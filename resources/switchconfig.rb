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
def configs_differ?(current, desired)
  # Get the current running config in a SwitchConfig object
  org_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', current)

  # Get the new running config in a SwitchConfig object
  new_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', desired)

  # Compare the current and new configs
  # If results are both empty then nothing needs to change,
  results = org_swc.compare(new_swc)
  !results[0].cmds.empty? || \
    !results[0].children.empty? || \
    !results[1].cmds.empty? || \
    !results[1].children.empty?
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
  if new_resource.force || configs_differ?(current_resource.content,
                                           new_resource.content)
    converge_by "Updating running-config. Force: #{new_resource.force}" do
      eos_v = switch.enable(['show version'])[0][:result]['version']
      # Introduced in 4.14.6M, Recommended for use in 4.15.0F
      if Gem::Version.new(eos_v) > Gem::Version.new('4.15')
        if new_resource.content
          file '/mnt/flash/startup-config' do
            #cookbook new_resource.cookbook
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
          command 'FastCli -p15 -c "configure replace startup-config"'
        end

      else
        Chef::Log.fatal 'Config replace requires EOS version 4.15 or higher.'
      end
    end
  end
end
