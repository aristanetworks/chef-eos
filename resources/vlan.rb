# eos_vlan resource
#
# Example:
#   eos_vlan '1' do
#     vlan_name 'default'
#     enable true
#     trunk_groups %w(mlag_ctl test)
#   end

property :vlan, Fixnum, name_property: true
# property :vlan, Fixnum, required: true
property :vlan_name, String
#property :switch_name, String, default: 'localhost'
property :switch_name, String, desired_state: false
property :enable, kind_of: [TrueClass, FalseClass], default: true
property :trunk_groups, Array
# property :trunk_groups, Array, default: []
# property :trunk_groups, Array, default: lazy { [] }
# property :trunk_groups, Array, default: lazy { default_trunk_groups }

# Defaults to the first action
default_action :create

#require_relative '_eos_eapi'
begin
  # Include gems vendored into this cookbook in the LOAD_PATH
  $LOAD_PATH.unshift(*Dir[::File.expand_path(
    '../../files/default/vendor/gems/**/lib', __FILE__)]
  )
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

require 'pry'

load_current_value do
  vlans = switch.api('vlans').getall
  current_value_does_not_exist! unless vlans.key?(vlan)

  vlan_name vlans[vlan][:name]
  state = vlans[vlan][:state]
  enable state == 'active' ? true : false
  trunk_groups vlans[vlan][:trunk_groups]

  # binding.pry
end

action :create do
  # converge_by "Creating vlan #{vlan}" do
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
    # binding.pry
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
  #return unless current_resource
  converge_by "Deleting vlan #{vlan}" do
    switch.api('vlans').destroy(vlan)
  end
end
