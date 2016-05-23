#
# Cookbook Name:: eos
# Recipe:: default
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

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

#ohai "reload" do
#  plugin "ipaddress"
#  action :nothing
#end

#template "#{node[:ohai][:plugin_path]}/ohai_lldp_neighbors.rb" do
#  source "ohai/ohai_lldp_neighbors.rb"
#  notifies :reload, "ohai[reload]"
#end

#include_recipe "ohai::default"
