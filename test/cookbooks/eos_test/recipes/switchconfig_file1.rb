#
# Cookbook Name:: eos_test
# Recipe:: switchconfig_file
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

eos_switchconfig 'running-config' do
  file_name 'config1.txt'
  action :create
end
