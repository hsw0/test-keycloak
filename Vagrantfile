# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "bento/centos-7.2"
  config.vm.hostname = "sandbox"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
  # prevent compromised vm overwriting vagrant files...
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: [ ".git", "shared" ]
  config.vm.synced_folder "shared", "/vagrant/shared"
  config.vm.provision "shell", path: "provision/scripts/provision.sh"
end
