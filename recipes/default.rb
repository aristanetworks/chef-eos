# Copyright (c) 2016, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.r
#
#  * Neither the name of Arista Networks nor the names of its contributors may
#  be used to endorse or promote products derived from this software without
#  specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ############################################################################

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
