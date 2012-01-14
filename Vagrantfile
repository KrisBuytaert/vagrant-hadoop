Vagrant::Config.run do |config|


config.vm.define :cloudera do |cloudera_config|
       cloudera_config.vm.box = "Centos6"
       cloudera_config.ssh.max_tries = 100
       cloudera_config.vm.host_name = "cloudera"
       cloudera_config.vm.provision :puppet do |cloudera_puppet|
       cloudera_puppet.pp_path = "/tmp/vagrant-puppet"
       cloudera_puppet.manifests_path = "manifests"
       cloudera_puppet.module_path = "modules"
       cloudera_puppet.manifest_file = "site.pp"
       end
  end

end
