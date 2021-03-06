#!/bin/bash

SAVED_OPTIONS=$(set +o)
set +e

read -r -d '' USERADD_LDIF_TPL <<-'EOF'
	dn:: $dn
	objectClass: top
	objectClass: person
	objectClass: organizationalPerson
	objectClass: user
	name: $username
	givenName:: $givenName
	sn:: $sn
	displayName:: $displayName
	mail:: $email
	sAMAccountName: $username
	userPrincipalName: $upn
	userAccountControl: 512
	unicodePwd:: $password
EOF

read -r -d '' GROUPADD_LDIF_TPL <<-'EOF'
	dn:: $dn
	objectClass: top
	objectClass: group
	sAMAccountName: $sam_account_name
EOF

read -r -d '' GROUPMEMS_LDIF_TPL <<-'EOF'
	dn:: $group_dn
	changetype: modify
	$op: member
	member:: $user_dn
EOF

eval "$SAVED_OPTIONS"
unset SAVED_OPTIONS

ad_useradd () {
	local ou="$1"
	local upn="$2"
	local password="$3"
	local firstname="$4" ; local lastname="$5"

	local email="$2" ; 
	local username="${upn%@*}"

	local password_enc=$(echo -n "\"$password\"" | iconv -f utf8 -t utf16le | base64)

	echo "$USERADD_LDIF_TPL" | sed -e "
	s|\\\$dn|$(echo -n "CN=$username,$ou" | base64 -w 0)|;
	s|\\\$username|$username|;
	s|\\\$upn|$upn|;
	s|\\\$givenName|$(echo -n "$firstname" | base64)|;
	s|\\\$sn|$(echo -n "$lastname" | base64)|;
	s|\\\$displayName|$(echo -n "$firstname $lastname" | base64)|;
	s|\\\$email|$(echo -n "$email" | base64)|;
	s|\\\$password|$password_enc|;
	" | 
	ldapadd -h "$server" -Q -Y GSSAPI
}

ad_groupadd () {
	local ou="$1"
	local cn="$2"
	local sam_account_name="$3"  # Windows 2000 이전, UNIX

	echo "$GROUPADD_LDIF_TPL" | sed -e "
	s|\\\$dn|$(echo -n "CN=$cn,$ou" | base64 -w 0)|;
	s|\\\$GROUPS_OU|$ou|;
	s|\\\$sam_account_name|$sam_account_name|;
	" |
	ldapadd -h "$server" -Q -Y GSSAPI
}

ad_groupmems () {
	local op="$1"  # add or delete
	local group_sam="$2"  # sAMAccountName
	local user_sam="$3"

	local LDAPSEARCH="ldapsearch -h $server -Q -Y GSSAPI -LLL -b $basedn"

	local group_dn=$($LDAPSEARCH "(&(objectClass=group)(sAMAccountName=$group_sam))" dn | sed -n 's/^\s*dn:\s*\(.*\)/\1/p')
	if [ -z "$group_dn" ]; then
		echo "Group not found" >&1
		return 1
	fi

	local user_dn=$($LDAPSEARCH "(&(objectClass=user)(sAMAccountName=$user_sam))" dn | sed -n 's/^\s*dn:\s*\(.*\)/\1/p')
	if [ -z "$user_dn" ]; then
		echo "Group not found" >&1
		return 1
	fi

	[[ "$group_dn" == :\ * ]] &&
		group_dn=$(echo "$group_dn" | cut -b3- | base64 --decode)
	[[ "$user_dn" == :\ * ]] &&
		user_dn=$(echo "$user_dn" | cut -b3- | base64 --decode)
	echo "$group_dn $user_dn"

	echo "$GROUPMEMS_LDIF_TPL" | sed -e "
	s|\\\$op|$op|;
	s|\\\$group_dn|$(echo -n "$group_dn" | base64 -w 0)|;
	s|\\\$user_dn|$(echo -n "$user_dn" | base64 -w 0)|;
	" |
	ldapmodify -h "$server" -Q -Y GSSAPI
}

