Vagrant::Config.run do |vagrant|
  define_list = [
    {
      :define  => :centos,
      :box     => "Berkshelf-CentOS-6.3-x86_64-minimal",
      :box_url => "http://dl.dropbox.com/u/31081437/Berkshelf-CentOS-6.3-x86_64-minimal.box",
      :pkgm    => :yum,
    },
#    {
#      :define  => :ubuntu,
#      :box     => "precise64",
#      :box_url => "http://files.vagrantup.com/precise64.box",
#      :pkgm    => :apt,
#    },
  ]

  define_list.each_with_index do |define, i|
    vagrant.vm.define define[:define] do |config|
      config.vm.box     = define[:box]
      config.vm.box_url = define[:box_url]

      config.vm.host_name = define[:define].to_s
      config.vm.network :hostonly, "192.168.50.#{i + 10}"

      config.vm.customize ["modifyvm", :id, "--memory", 512]
      config.vm.customize ["modifyvm", :id, "--cpus", 4]
    end
  end
end
