
yum_install() {
	pkgs=$@
	for pkg in $pkgs ; do
		rpm -qi --quiet "$pkg" || yum install -y $pkg
	done
}

