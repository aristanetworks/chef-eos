begin
  require 'rbeapi'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Chef::Log.debug msg
end

Ohai.plugin(:LldpNeighbors) do
  provides 'lldp_neighbors'

  # TODO:  Need to restrict to AristaEOS
  #collect_data(:AristaEOS) do
  collect_data do
    Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
    connection_name = ENV['RBEAPI_CONNECTION'] || 'localhost'
    switch = Rbeapi::Client.connect_to(connection_name)
    #require 'pry'

    neighbors = switch.enable('show lldp neighbors')

    #binding.pry
    if neighbors[0][:encoding] == 'json'
      newhash = Hash.new { |hash, key| hash[key] = [] }
      neighbors[0][:result]['lldpNeighbors'].each { |n| newhash[n['port']] << n }
      #binding.pry
      # Return the hash as lldp_neighbors
      lldp_neighbors newhash
    end
  end
end
