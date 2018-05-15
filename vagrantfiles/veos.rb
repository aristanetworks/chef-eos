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

  ############################
  # BEGIN install.sh workaround
  #
  # Temporary until the following get released:
  # https://github.com/chef/mixlib-install/pull/127
  # https://github.com/chef/omnitruck/pull/192
  #
  # Remove when install.sh contains "arista_eos"
  #   wget https://omnitruck.chef.io/install.sh
  #   grep arista_eos install.sh
  #
  require 'net/http'
  require 'uri'
  chef_meta = 'https://omnitruck.chef.io/stable/chef/metadata'\
              '?p=arista_eos&pv=6&m=x86_64'
  url = URI(chef_meta)
  chef_url = Net::HTTP.get(url).split("\n")[2].split[1]
                      .gsub(/x86_64/, 'i386')
  chef_rpm = URI(chef_url).path.split('/').last
  File.write("../#{chef_rpm}",
             Net::HTTP.get(URI.parse(chef_url)))
  config.vm.provision 'file',
                      source: "../#{chef_rpm}",
                      destination: "/mnt/flash/#{chef_rpm}"
  config.vm.provision 'shell', inline: <<-SHELL
    sudo rpm -Uvh /mnt/flash/#{chef_rpm}
    SHELL
  # END install.sh workaround
  ############################

  config.vm.provision 'shell', inline: <<-SHELL
    sleep 30
    FastCli -p 15 -c 'configure
    ip route 0.0.0.0/0 10.0.2.2
    end'
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
