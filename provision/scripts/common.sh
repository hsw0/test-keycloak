
yum_install() {
	pkgs=$@
	to_be_installed=""

	for pkg in $pkgs ; do
		rpm -qi --quiet "$pkg" || to_be_installed="$to_be_installed $pkg"
	done

	[ -z "$to_be_installed" ] && return

	yum install -y $to_be_installed
}

