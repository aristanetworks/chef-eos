# Settings that require eAPI are in a separate file from the base platform
# match so that the platform/os will still get set even if rbeapi is missing.
#
require 'ohai/mixin/os'
begin
  require 'rbeapi'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Ohai::Log.debug msg
  false
end

Ohai.plugin(:Eos) do
  provides 'os_version', 'eos_version', 'eos_internal_version', 'serial_number',
           'model', 'system_mac'

  # /etc/Eos-release:
  # "Arista Networks EOS 4.14.6M"

  collect_data do
    if File.exist?('/etc/Eos-release')
      Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
      connection_name = ENV['RBEAPI_CONNECTION'] || 'localhost'
      switch = Rbeapi::Client.connect_to(connection_name)
      response = switch.enable('show version')
      version = response[0][:result]

      os_version version['version']
      platform_version version['version']
      eos_version version['version']
      eos_internal_version version['internalVersion']
      serial_number version['serialNumber']
      model version['modelName']
      system_mac version['systemMacAddress']
    end
  end
end
