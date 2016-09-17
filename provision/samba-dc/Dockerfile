FROM phusion/baseimage:0.9.19

CMD ["/sbin/my_init"]

RUN true && \
	export DEBIAN_FRONTEND='noninteractive' && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		samba samba-dsdb-modules samba-vfs-modules winbind \
		krb5-user ldap-utils libsasl2-modules-gssapi-mit && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

RUN mkdir /etc/service/samba-ad-dc
ADD svc-samba-ad-dc.sh /etc/service/samba-ad-dc/run
ADD provision.sh /etc/my_init.d/provision.sh

VOLUME ["/etc/samba", "/var/lib/samba/private"]
