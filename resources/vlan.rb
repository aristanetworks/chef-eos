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

# eos_vlan resource
#
# Example:
#   eos_vlan '1' do
#     vlan_name 'default'
#     enable true
#     trunk_groups %w(mlag_ctl test)
#   end

property :vlan, Fixnum, name_property: true
property :vlan_name, String
property :switch_name, String, desired_state: false
property :enable, kind_of: [TrueClass, FalseClass], default: true
property :trunk_groups, Array

# Defaults to the first action
default_action :create

begin
  require 'rbeapi'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Chef::Log.debug msg
end

##
# Instance of Rbeapi::Client::Node used to sending and receiving
# eAPI messages.  In addition, the switch object provides access to
# Ruby Client for eAPI API modules used to configure EOS resources.
#
# @return [Node] An instance of Rbeapi::Client::Node used to send
#   and receive eAPI messages
def switch
  return @switch if @switch
  Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
  connection_name = ENV['RBEAPI_CONNECTION'] || switch_name || 'localhost'
  @switch = Rbeapi::Client.connect_to(connection_name)
end

load_current_value do
  vlans = switch.api('vlans').getall
  current_value_does_not_exist! unless vlans.key?(vlan)

  vlan_name vlans[vlan][:name]
  state = vlans[vlan][:state]
  enable state == 'active' ? true : false
  trunk_groups vlans[vlan][:trunk_groups]
end

action :create do
  converge_if_changed :vlan do
    switch.api('vlans').create(vlan)
  end

  converge_if_changed :vlan_name do
    switch.api('vlans').set_name(vlan, value: vlan_name)
  end

  converge_if_changed :enable do
    state = enable == true ? 'active' : 'suspend'
    switch.api('vlans').set_state(vlan, value: state)
  end

  converge_if_changed :trunk_groups do
    # trunk_groups needs more complex logic to reconcile with add/remove
    add = new_resource.trunk_groups - current_resource.trunk_groups
    remove = current_resource.trunk_groups - new_resource.trunk_groups
    add.each do |group|
      switch.api('vlans').add_trunk_group(vlan, group)
    end

    remove.each do |group|
      switch.api('vlans').remove_trunk_group(vlan, group)
    end
  end
end

action :delete do
  converge_by "Deleting vlan #{vlan}" do
    switch.api('vlans').destroy(vlan)
  end
end
