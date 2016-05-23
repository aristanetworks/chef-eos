Vagrant.configure('2') do |c|

  c.vm.provision 'file', source:
      '/Users/jere/Demos/chef/chef-12.6.0-1.el6.i386.rpm",
      destination: "/mnt/flash/chef-12.6.0-1.el6.i386.rpm'

  c.vm.provision 'shell', inline: <<-SHELL
    FastCli -p 15 -c "configure
  !  hostname node_name
    ip domain-name aristanetworks.com
    ip name-server 10.0.2.3
    ip route 0.0.0.0/0 10.0.2.2
    !ip host ztps.ztps-test.com 172.16.130.10
   interface Ethernet1
       !no switchport
  !     ip address ip/24
       no shutdown
  !  username admin privilege 15 role network-admin secret admin
    username serverspec privilege 15 role network-admin secret serverspec
  !  interface Management1
  !     description Provisioned by Vagrant
    management api http-commands
    protocol unix-socket
    end
    !copy running-config startup-config
    copy flash:chef-12.6.0-1.el6.i386.rpm extension:
    delete flash:chef-12.6.0-1.el6.i386.rpm
    extension chef-12.6.0-1.el6.i386.rpm"
    !copy installed-extensions boot-extensions
    sudo install -d -o serverspec -g eosadmin -m 0700 ~serverspec/.ssh/
    sudo install -o serverspec -g eosadmin -m 0600 ~root/.ssh/authorized_keys ~serverspec/.ssh/
    sudo ln -s /opt/chef/bin/chef-client /bin/chef-client
    sudo ln -s /opt/chef/bin/chef-solo /bin/chef-solo
    sudo ln -s /opt/chef/bin/chef-apply /bin/chef-apply
  SHELL
end
