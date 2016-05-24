# eos Cookbook for Arista EOS

The eos cookbook simplifies management of [Arista](https://www.arista.com/) EOS network devices.  Arista EOS uses the standard CentOS 32-bit Chef client.  By including the eos::default recipe in your runlist performs the following actions needed on EOS:
- Relocate /etc/chef to /petsist/sys/chef with a symlink back to /etci/chef 
- Enable eAPI (‘management api http-commands’) with unix-sockets as the transport in the running-config
- Adds/enhances several ohai plugins

# Requirements

This cookbook is designed and tested with Chef 12 and EOS 4.15. Other versions may work but are not fully tested at this time.

# Installing

Installing Chef on an Arista switch requires the following steps:

- [Download the Chef client](https://downloads.chef.io/chef-client/redhat/) for RedHat/CentOS (32-bit)
- Copy the rpm to the switch
  ```
  Arista#copy http://my_server/path/chef-12.6.0-1.el6.i386.rpm extension:
  ```
- Install the RPM:
  ```
  Arista#extension chef-12.6.0-1.el6.i386.rpm
  ```
- Configure EOS to install the chef-client after a reload
  ```
  Arista#copy installed-extensions boot-extensions
  ```
- Ensure recipe[‘eos’] is in the default runlist for any EOS devices

# Using

There are 2 general methods to use this cookbook to manage an Arista switch: eos_switchconfig, which manages the running-config from a template, and discrete resources such as eos_vlan. eos_switchconfig is the recommended method at this time.  However, eos_vlan was written to serve as an example for additional discrete resources to be managed, if desired.

## eos_switchconfig

```ruby
eos_switchconfig 'running-config' do
  action :create
  source 'veos_config.erb'
  variables({
    hostname: 'veos01',
    domainname: 'example.com',
    nameservers: ['10.0.2.3'],
    ntp_server: '10.0.2.3',
    ntp_source_intf: 'Management1',
    static_routes: {
      '0.0.0.0/0' => '10.0.2.2'
    },
    l3ports: [
      Ethernet1: {
        ip_addr: '192.168.8.2/24'
      }
    ],
    l2ports: [
      Ethernet2: {},
      Ethernet3: {},
      Ethernet4: {}
    ]
  })
end
```

```ruby
running_config = <<-ENDCONFIG
! Command: show running-config
! device: veos01 (vEOS, EOS-4.14.6M)
!
! boot system flash:/vEOS-lab.swi
!
alias chef bash sudo chef-client
!
hostname veos01
ip name-server vrf default 10.0.2.3
ip domain-name example.com
!
spanning-tree mode mstp
!
aaa authorization exec default local
!
aaa root secret 5 <removed>
!
username admin privilege 15 role network-admin secret 5 <removed>
username vagrant privilege 15 role network-admin secret 5 <removed>
!
interface Ethernet1
   no switchport
   ip address 192.0.2.12 Ethernet2
!
interface Ethernet3
!
interface Ethernet4
!
interface Management1
   description Provisioned by Vagrant
   ip address 10.0.2.15/24
!
ip route 0.0.0.0/0 10.0.2.2
!
no ip routing
!
management api http-commands
   protocol unix-socket
   no shutdown
!
end
ENDCONFIG

eos_switchconfig 'running-config' do
  action :create
  #content IO.read('/mnt/flash/running.cfg')
  content running_config
end
```

# Contributing

Community contributions are welcome.  Please ensure all pull-requests include spec tests.

# Authors & Support

For support, please open a GitHub issue.  This module is maintained by Arista [EOS+ Consulting Services](mailto://eosplus-dev@arista.com).Commercial support options are available upon request.

# License

All files in this package are covered by the included [license](../blob/EFT1/LICENSE) unless otherwise noted.
