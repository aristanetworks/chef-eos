#
# Cookbook Name:: eos
# Recipe:: vlan
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

eos_vlan '5' do
  vlan_name 'Test_VLAN_5'
  enable true
  trunk_groups %w(mlag_ctl test)
end

eos_vlan '6' do
  action :create
  vlan_name 'Test_VLAN_6'
  enable true
  trunk_groups %w(mlag_ctl test)
end
