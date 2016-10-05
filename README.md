# eos Cookbook for Arista EOS

The eos cookbook simplifies management of [Arista](https://www.arista.com/) EOS
network devices.  Arista EOS uses the standard el6 32-bit Chef client.  By
including the eos::default recipe in your runlist, it will perform the
following actions needed on EOS:
- Relocate /etc/chef to /persist/sys/chef with a symlink back to /etc/chef
- Enable eAPI (‘management api http-commands’) with unix-sockets as the
  transport in the running-config
- Add/enhances several ohai plugins

# Requirements

This cookbook is designed and tested with Chef 12 and EOS 4.15 and 4.16. Other
versions are likely to work but are not fully tested at this time.

  - Arista EOS 4.15 or greater
  - Chef client 32-bit RPM for RedHat/CentOS/el
  - Arista Ruby client for eAPI (rbeapi) rubygem and dependencies:
    - rbeapi 0.6.0 or greater which requires:
      - netaddr
      - net_http_unix
      - inifile

# Installing

Installing Chef on an Arista switch requires the steps below. While the
manual steps are displayed, below, for reference, it is suggested to use a tool
such as Arista’s CloudVision or ZTP Server to take advantage of the zero-touch
provisioning capability of Arista devices to load a desired EOS version,
additional packages, and a base config, automatically.

- [Download the Chef client](https://downloads.chef.io/chef-client/redhat/)
  for RedHat/CentOS (32-bit)
- Copy the rpm to the switch.

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

- Ensure `recipe[‘eos’]` is in the default runlist for any EOS devices

## Installing behind a firewall

By default, the chef_gem resource will reach out to rubygems.org to find the
necessary rubygems.  When installing on devices without access to the Internet,
additional steps are required.  These, too, should be automated whenever
possible.

One solution is to download the rubygem binaries to the Chef server, then use a
recipe to install those on devices.  Example:

Download the rubygem binaries:

```
gem fetch inifile
gem fetch netaddr
gem fetch net_http_unix
gem fetch rbeapi
```

Then, create a recipe to copy these files to nodes and install the packages:

```
cookbook_file “#{Chef::Config[:file_cache_path]}/rbeapi.gem” do
  source ‘rbeapi-0.4.0.gem’
end
resources(:cookbook_file => “#{Chef::Config[:file_cache_path]}/rbeapi.gem”).run_action(:create)

chef_gem ‘rbeapi’ do
  source “#{Chef::Config[:file_cache_path]}/rbeapi.gem”
  version ‘0.4.0’
  compile_time false
  action :upgrade
end
```

NOTE: the chef_gem resource requires the `version` to be specified when
installing from a local file.

Finally, include that recipe in the EOS device’s default runlist.
`recipe[eos::rbeapi_local]`

# Using

There are 2 general methods to use this cookbook to manage an Arista switch:
Managing the entire config as a whole or using discrete resources. The
eos_switchconfig resource manages the running-config from a template or file.
Discrete resources, such as eos_vlan, provide selective, granular management of
individual components. Eos_switchconfig is the recommended method for most
network teams. However, eos_vlan is provided to serve as an example for
additional discrete resources to be managed, if desired.

## eos_switchconfig

```ruby
eos_switchconfig 'running-config' do
  action :create
  source 'eos_config.erb'
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

For more examples, see the [test recipes](test/cookbooks/eos_test/recipes).

# Contributing

Community contributions are welcome.  Please ensure all pull-requests include
spec tests. See [CONTRIBUTING](CONTRIBUTING.md) for more detail.

# Authors & Support

For support, please open a GitHub issue.  This module is maintained by Arista
[EOS+ Consulting Services](mailto://eosplus-dev@arista.com). Commercial support
options are available upon request.

# License

All files in this package are covered by the included BSD 3-clause
[license](LICENSE) unless otherwise noted.
