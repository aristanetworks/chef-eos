#
# Cookbook Name:: eos
# Recipe:: vlan
#
# Copyright (c) 2016 The Authors, All Rights Reserved.


eos_vlan '5' do
  #action :create
  vlan_name 'jere05'
  enable true
  # trunk_groups ['mlag_ctl', 'test']
  trunk_groups %w(mlag_ctl test)
end
