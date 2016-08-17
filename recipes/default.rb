#
# Cookbook Name:: eos
# Recipe:: default
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

directory '/persist/sys/chef' do
  recursive true
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

link '/etc/chef' do
  to '/persist/sys/chef'
end

execute 'Enable eAPI' do
  command <<-EOF
    /usr/bin/FastCli -p 15 -c 'enable
    configure
    management api http-commands
    protocol unix-socket
    no shutdown
    end'
  EOF
  not_if '/usr/bin/FastCli -p 15 -c "show running-config" | grep unix-socket'
end

chef_gem 'rbeapi' do
  compile_time true
end

ohai_plugin 'eos' do
  source_file 'ohai/eos.rb'
end

ohai_plugin 'eos_hostname' do
  source_file 'ohai/eos_hostname.rb'
end

ohai_plugin 'eos_lldp_neighbors' do
  source_file 'ohai/eos_lldp_neighbors.rb'
end
