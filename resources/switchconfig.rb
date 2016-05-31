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
#   rubocop:disable Lint/RescueException

property :config_file, String, name_property: true
property :switch_name, String, desired_state: false
property :content, String, required: false
property :source, String, required: false, desired_state: true
property :variables, Hash, required: false, desired_state: true
property :force, kind_of: [TrueClass, FalseClass], default: false,
                 desired_state: false

default_action :create

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
#   and receive eAPI messages
def switch
  return @switch if @switch
  Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
  connection_name = ENV['RBEAPI_CONNECTION'] || switch_name || 'localhost'
  @switch = Rbeapi::Client.connect_to(connection_name)
end

##
# run_commands runs the array of commands on the switch.
# If running the commands failed and a backup filename was
# specified then restore the backup configuration.
#
# @param cmds [Array<String>] The commands to run on the switch.
# @param bu_filename [String] The backup filename.
def run_commands(cmds)
  return unless cmds.length > 0
  switch.config(cmds)
end

##
# process_config process the switch config resource and applies
# the required changes to the switch.
#
def process_config(current, desired, force)
  bu_filename = ''

  # If force flag set then just apply the new config to the switch,
  # otherwise get current running config and diff with new config.
  if force == true
    #TODO: notice 'Force flag enabled, overwriting existing config'
    #TODO: Should this be 'config replace', when available?
    cmds = desired.global.gen_commands
  else
    # Compare the existing and new config
    # If results are both empty then nothing needs to change,
    # run_commands won't do anything for this case.
    results = current.compare(desired)

    # Set the switch configuration commands that are in the existing
    # configuration, but not in the new configuration, to their
    # default value.
    default_cmds = results[0].gen_commands(add_default: true)
    run_commands(default_cmds, bu_filename)

    # Generated the commands to add to the current switch configuration
    cmds = results[1].gen_commands
  end

  run_commands(cmds, bu_filename)
end

load_current_value do |desired_resource|
  # Get the current values from the switch
  content switch.get_config(config: 'running-config', as_string: true)

  if desired_resource.source
    # A template was passed to us
    require 'chef/mixin/template'
    @template_context = Chef::Mixin::Template::TemplateContext.new({})

    # Get the file path to the template in the cookbook
    templates = run_context.cookbook_collection['eos'].template_filenames
    source_path = ''
    templates.each do |tpath|
      source_path = tpath if tpath.end_with? desired_resource.source
    end
    if source_path.empty?
      Chef::Log.fatal "Unable to locate template: #{desired_resource.source}"
    end

    # Copy any variables in to the template context
    if desired_resource.variables
      desired_resource.variables.each do |key, value|
        @template_context[key] = value
      end
    end

    # Render the template to a string
    desired_resource.content @template_context.render_template(source_path)
  end
end

action :create do
  # Get the current running config in a SwitchConfig object
  org_swc = Rbeapi::SwitchConfig::SwitchConfig.new('',
                                                   current_resource.content)

  # Get the new running config in a SwitchConfig object
  new_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', new_resource.content)

  # Compare the current and new configs
  # If results are both empty then nothing needs to change,
  # run_commands won't do anything for this case.
  results = org_swc.compare(new_swc)
  swc_equal = results[0].cmds.empty? && \
              results[0].children.empty? && \
              results[1].cmds.empty? && \
              results[1].children.empty?

  if new_resource.force || !swc_equal
    converge_by "Updating running-config. Force: #{new_resource.force}" do
      process_config(org_swc,
                     new_swc,
                     new_resource.force)
    end
  end
end
