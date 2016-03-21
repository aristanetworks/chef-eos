#
# Cookbook Name:: eos
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

directory "/persist/sys/chef" do
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
    no potocol https
    protocol http
    protocol unix-socket
    no shutdown
    end'
  EOF
  not_if '/usr/bin/FastCli -p 15 -c "show running-config" | grep unix-socket'
end

chef_gem 'netaddr' do
  source '/mnt/flash/netaddr-1.5.1.gem'
  version '1.5.1'
  compile_time false
end
chef_gem 'net_http_unix' do
  source '/mnt/flash/net_http_unix-0.2.1.gem'
  version '0.2.1'
  compile_time false
end
chef_gem 'inifile' do
  source '/mnt/flash/inifile-3.0.0.gem'
  version '3.0.0'
  compile_time false
end

# Include the rbeapi rubygem and ensure it is installed for Chef's ruby
cookbook_file "#{Chef::Config[:file_cache_path]}/rbeapi.gem" do
  source 'rbeapi-0.5.1.gem'
end
resources(:cookbook_file => "#{Chef::Config[:file_cache_path]}/rbeapi.gem").run_action(:create)

chef_gem 'rbeapi' do
  source "#{Chef::Config[:file_cache_path]}/rbeapi.gem"
  version '0.5.1'
  compile_time false
  action :upgrade
end

#ohai "reload" do
#  plugin "ipaddress"
#  action :nothing
#end

#template "#{node[:ohai][:plugin_path]}/ohai_lldp_neighbors.rb" do
#  source "ohai/ohai_lldp_neighbors.rb"
#  notifies :reload, "ohai[reload]"
#end

#include_recipe "ohai::default"

