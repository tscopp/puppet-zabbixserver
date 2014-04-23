Vagrant.configure("2") do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'
  config.vm.hostname = 'zabbix.berkeley.edu'
  config.vm.network "private_network", type: "dhcp"
  config.vm.network :forwarded_port, host: 80, guest: 8080
  config.vm.network :forwarded_port, host: 443, guest: 4430
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "puppet/manifests/"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "puppet/modules/"
  end
end
