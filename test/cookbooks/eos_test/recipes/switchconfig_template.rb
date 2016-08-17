eos_switchconfig 'running-config' do
  action :create
  source 'switchconfig_test'
  variables(hostname: 'veos01',
            domainname: 'example.com',
            nameservers: ['10.0.2.3'],
            ntp_server: '10.0.2.3',
            ntp_source_intf: 'Management1',
            static_routes: {
              '0.0.0.0/0' => '10.0.2.2'
            },
            l3ports: [
              Ethernet1: {
                ip_addr: '172.16.130.181/24'
              }
            ],
            l2ports: [
              Ethernet2: {},
              Ethernet3: {},
              Ethernet4: {}
            ])
end
