# -*- mode: ruby -*-
# # vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # Ethernet1
  config.vm.network 'private_network', virtualbox__intnet: true,
                                       ip: '169.254.1.11', auto_config: false
  # Ethernet2
  config.vm.network 'private_network', virtualbox__intnet: true,
                                       ip: '169.254.1.11', auto_config: false

  config.vm.provision 'shell', inline: <<-SHELL
    sleep 30
    FastCli -p 15 -c 'configure
    ip route 0.0.0.0/0 10.0.2.2
    end'
    SHELL

  # Temporary until the following get released:
  # https://github.com/chef/mixlib-install/pull/127
  # https://github.com/chef/omnitruck/pull/192
  config.vm.provision 'file',
                      source: 'chef-12.13.30-1.el6.i386.rpm',
                      destination: '/mnt/flash/chef-12.13.30-1.el6.i386.rpm'
  config.vm.provision 'shell', inline: <<-SHELL
    FastCli -p 15 -c 'bash sudo rpm -Uvh /mnt/flash/chef-12.13.30-1.el6.i386.rpm'
    SHELL

  config.vm.provision 'shell', inline: <<-SHELL
    sleep 30
    FastCli -p 15 -c 'configure
    ip route 0.0.0.0/0 10.0.2.2
    end
    bash sudo rpm -Uvh /mnt/flash/chef-12.13.30-1.el6.i386.rpm'
    SHELL
  config.vm.provider :virtualbox do |v|
    # Networking:
    #  nic1 is always Management1 which is set to dhcp in the basebox.

    # Patch Ethernet1 to a particular internal network
    v.customize ['modifyvm', :id, '--nic2', 'intnet',
                 '--intnet2', 'vEOS-intnet1']
    # Patch Ethernet2 to a particular internal network
    v.customize ['modifyvm', :id, '--nic3', 'intnet',
                 '--intnet3', 'vEOS-intnet2']
  end
end
