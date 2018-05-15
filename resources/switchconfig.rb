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

# eos_switchconfig resource
#
# Note: resource name must always be 'running-config' and
# sub-blocks must be indented with the normal 3-spaces.
#
# Examples:
#   config = '
#   hostname someswitch
#   !
#   interface Ethernet 4
#      description This managed by Chef
#      switchport mode access
#      switchport access vlan 999
#      shutdown
#   !'

#   eos_switchconfig 'running-config' do
#     content config
#     action :create
#   end
#
#   eos_switchconfig 'running-config' do
#     action :create
#     source 'eos_config.erb'
#     variables({
#       hostname: 'veos01',
#       domainname: 'example.com',
#       nameservers: ['10.0.2.3'],
#       ntp_server: '10.0.2.3',
#       ntp_source_intf: 'Management1',
#       static_routes: {
#         '0.0.0.0/0' => '10.0.2.2'
#       },
#       l3ports: [
#         Ethernet1: {
#           ip_addr: '172.16.130.181/24'
#         }
#       ],
#       l2ports: [
#         Ethernet2: {},
#         Ethernet3: {},
#         Ethernet4: {}
#       ]
#     })
#   end
#

property :config_file, String, name_property: true
property :switch_name, String, desired_state: false
property :content, String, required: false
property :file_name, String, required: false
property :source, String, required: false, desired_state: true
property :variables, Hash, required: false, desired_state: true
property :force, kind_of: [TrueClass, FalseClass], default: false,
                 desired_state: false

default_action :create

require 'pry'
begin
  require 'rbeapi'
  require 'rbeapi/switchconfig'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Chef::Log.debug msg
end

##
# Instance of Rbeapi::Client::switch used to sending and receiving
# eAPI messages.  In addition, the switch object provides access to
# Ruby Client for eAPI API modules used to configure EOS resources.
#
# @return [switch] An instance of Rbeapi::Client::switch used to send
#   and receive eAPI messages.
def switch
  return @switch if @switch
  Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
  connection_name = ENV['RBEAPI_CONNECTION'] || switch_name || 'localhost'
  @switch = Rbeapi::Client.connect_to(connection_name)
end

##
# Perform a block-by-clock diff of the current and desired configs.
# This allows for user input in which blocks are not in the same order
# as 'show running-config'.
#
# @param [current] <String> The running-config from the switch.
# @param [desired] <String> The proposed config from the user.
# @return [Boolean] whether configurations differ
# rubocop:disable AbcSize
def configs_differ?(current, desired)
  # Get the current running config in a SwitchConfig object
  org_swc = Rbeapi::SwitchConfig::SwitchConfig.new(current)

  # Get the new running config in a SwitchConfig object
  new_swc = Rbeapi::SwitchConfig::SwitchConfig.new(desired)

  # Compare the current and new configs
  # If results are both empty then nothing needs to change,
  results = org_swc.compare(new_swc)
  !results[0].cmds.empty? || \
    !results[0].children.empty? || \
    !results[1].cmds.empty? || \
    !results[1].children.empty?
end
# rubocop:enable AbcSize

load_current_value do |desired_resource|
  # Get the current values from the switch
  current = switch.get_config(config: 'running-config', as_string: true)

  if desired_resource.source
    source desired_resource.source
    # A template was passed to us
    require 'chef/mixin/template'
    @template_context = Chef::Mixin::Template::TemplateContext.new({})

    # Get the file path to the template in the cookbook
    templates = run_context.cookbook_collection[desired_resource.cookbook_name]
                           .template_filenames
    source_path = ''
    templates.each do |tpath|
      source_path = tpath if tpath =~ /#{desired_resource.source}(.erb)?$/
    end
    if source_path.empty?
      Chef::Log.fatal "Unable to locate template: #{desired_resource.source}"
    end

    # Copy any variables in to the template context
    if desired_resource.variables
      variables desired_resource.variables
      desired_resource.variables.each do |key, value|
        @template_context[key] = value
      end
    end

    # Render the template to a string
    desired_resource.content @template_context.render_template(source_path)
  elsif desired_resource.file_name
    file_name desired_resource.file_name

    # Get the file path in the cookbook
    files = run_context.cookbook_collection[desired_resource.cookbook_name]
                       .file_filenames
    source_path = ''
    files.each do |fpath|
      source_path = fpath if fpath.end_with? desired_resource.file_name
    end
    if source_path.empty?
      Chef::Log.fatal "Unable to locate file: #{desired_resource.source}"
    end
    desired_resource.content IO.read(source_path)
  end

  # Use the block-compare to determine if the configs are different
  if !configs_differ?(current, desired_resource.content)
    content desired_resource.content
  else
    content current
  end
end

action :create do
  converge_if_changed do
    eos_v = switch.enable(['show version'])[0][:result]['version']
    # Introduced in 4.14.6M, Recommended for use in 4.15.0F
    if Gem::Version.new(eos_v) > Gem::Version.new('4.15')
      if new_resource.content
        file '/mnt/flash/startup-config' do
          content new_resource.content
        end
      elsif new_resource.resource.eql?(:cookbook_file)
        cookbook_file '/mnt/flash/startup-config' do
          cookbook new_resource.cookbook
          source new_resource.source_file
        end
      elsif new_resource.resource.eql?(:template)
        template '/mnt/flash/startup-config' do
          cookbook new_resource.cookbook
          source new_resource.source_file
          variables new_resource.variables
        end
      end

      execute 'replace running-config' do
        command 'FastCli -p15 -c "configure replace flash:startup-config"'
      end

    else
      Chef::Log.fatal 'Config replace requires EOS version 4.15 or higher.'
    end
  end
end
