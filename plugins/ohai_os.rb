require 'ohai/mixin/os'
begin
  require 'rbeapi'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Chef::Log.debug msg
end

Ohai.plugin(:Os) do
  provides 'os', 'os_version'
  depends 'kernel'

  # /etc/Eos-release:Arista Networks EOS 4.14.6M

  collect_data do
    if File.exist?('/etc/Eos-release')
      Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
      connection_name = ENV['RBEAPI_CONNECTION'] || 'localhost'
      switch = Rbeapi::Client.connect_to(connection_name)
      response = switch.enable('show version')
      version = response[0][:result]
      # require 'pry'
      # binding.pry

      os 'AristaEOS'
      #platform 'AristaEOS'
      os_version version['version']
      #platform_version version['version']
      eos_version version['version']
      eos_internal_version version['internalVersion']
      serial_number version['serialNumber']
      model version['modelName']
    end
  end
end
