# -*- mode: ruby -*-
# vi: set ft=ruby :

DOMAIN = "example.com"
HOSTNAME_SUFFIX = "." + DOMAIN

Vagrant.configure(2) do |config|
  # Samba 4 AD DC 구성.
  # RHEL 계열에는 Kerberos 라이브러리 관련 문제로 도메인 컨트롤러가 빠져 있어 
  # 어쩔 수 없이 Ubuntu 16.04 사용.
  config.vm.define "dc1", autostart: true do |node|
    node.vm.box = "ubuntu/xenial64"
    node.vm.hostname = "dc1" + HOSTNAME_SUFFIX
    node.vm.network "private_network", ip: "192.168.33.224"
    node.vm.provider :virtualbox do |vb|
      vb.memory = 384
    end
    node.vm.provision "shell", path: "provision/samba-dc/provision.sh"
  end

  # Keycloak
  config.vm.define "idsvc", autostart: true do |node|
    node.vm.box = "bento/centos-7.4"
    node.vm.hostname = "idsvc" + HOSTNAME_SUFFIX
    node.vm.network "private_network", ip: "192.168.33.225"
    node.vm.provider :virtualbox do |vb|
      vb.memory = 512
    end
    node.vm.provision :ansible, run: "always" do |ansible|
      ansible.playbook = "provision/playbook.yml"
      ansible.become = true
      ansible.compatibility_mode = "2.0"
    end
  end

  # Keycloak 연동 예제
  config.vm.define "examples", autostart: true do |node|
    node.vm.box = "bento/centos-7.2"
    node.vm.hostname = "examples" + HOSTNAME_SUFFIX
    node.vm.network "private_network", ip: "192.168.33.226"
    node.vm.provider :virtualbox do |vb|
      vb.memory = 512
    end
    node.vm.provision :ansible, run: "always" do |ansible|
      ansible.playbook = "provision/playbook.yml"
      ansible.become = true
      ansible.compatibility_mode = "2.0"
    end
  end

  # prevent compromised vm overwriting vagrant files...
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: [ ".git", "shared", ".*.sw[a-z]" ]
  config.vm.synced_folder "shared", "/vagrant/shared"
end
