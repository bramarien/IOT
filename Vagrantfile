# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"


  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.network "forwarded_port", guest: 3128, host: 3128

  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
     vb.memory = "8000"
     vb.cpus = 12
   end

   config.vm.provision "shell", path: "scripts/vm_startup.sh"
end
