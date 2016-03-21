Vagrant.configure("2") do |c|

  #c.vm.provision "file", source: "files/extensions/puppet-enterprise-3.7.2-eos-4-i386.swix", destination: "/mnt/flash/puppet-enterprise-3.7.2-eos-4-i386.swix"

  c.vm.provision "shell", inline: <<-SHELL
    FastCli -p 15 -c "configure
  !  hostname node_name
    ip domain-name ztps-test.com
    !ip host ztps.ztps-test.com 172.16.130.10
    !ip host puppet 172.16.130.10
   interface Ethernet1
       !no switchport
  !     ip address ip/24
       no shutdown
  !  alias pa bash sudo puppet agent --environment demo --waitforcert 30
  !  alias puppet bash sudo puppet
  !  username admin privilege 15 role network-admin secret admin
    username serverspec privilege 15 role network-admin secret serverspec
  !  interface Management1
  !     description Provisioned by Vagrant
    management api http-commands
    protocol unix-socket
    end
    sudo install -d -o serverspec -g eosadmin -m 0700 ~serverspec/.ssh/
    sudo install -o serverspec -g eosadmin -m 0600 ~root/.ssh/authorized_keys ~serverspec/.ssh/"
  #  copy running-config startup-config
  #  !copy flash:puppet-enterprise-3.7.2-eos-4-i386.swix extension:
  #  !copy flash:rbeapi-0.1.0.swix extension:
  #  !delete flash:puppet-enterprise-3.7.2-eos-4-i386.swix
  #  !delete flash:rbeapi-0.1.0.swix
  #  !extension puppet-enterprise-3.7.2-eos-4-i386.swix
  #  !extension rbeapi-0.1.0.swix
  #  !copy installed-extensions boot-extensions"
  SHELL
end
