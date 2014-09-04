# -*- mode: ruby *-*
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = 'puppetlabs/ubuntu-14.04-64-puppet'
  config.vm.hostname = 'zabbix.berkeley.edu'
  config.vm.network "private_network", type: "dhcp"
  config.vm.network :forwarded_port, host: 800, guest: 80
  config.vm.network :forwarded_port, host: 4440, guest: 443
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests/"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "puppet/modules/"
  end
end
