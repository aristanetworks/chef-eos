begin
  require 'rbeapi'
rescue LoadError
  msg = 'Unable to load rbeapi rubygem'
  Ohai::Log.debug msg
  false
end

Ohai.plugin(:LldpNeighbors) do
  provides 'lldp_neighbors'

  collect_data(:arista_eos) do
    Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
    connection_name = ENV['RBEAPI_CONNECTION'] || 'localhost'
    switch = Rbeapi::Client.connect_to(connection_name)

    neighbors = switch.enable('show lldp neighbors')

    if neighbors[0][:encoding] == 'json'
      newhash = Hash.new { |hash, key| hash[key] = [] }
      neighbors[0][:result][:lldpNeighbors].each { |n| newhash[n[:port]] << n }

      # Return the hash as lldp_neighbors
      lldp_neighbors newhash
    end
  end
end
