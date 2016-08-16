Ohai.plugin(:Hostname) do
  provides 'domain', 'hostname', 'fqdn', 'machinename'

  collect_data(:arista_eos) do
    so = shell_out("FastCli -c 'show hostname'")
    so = so.stdout.split($INPUT_RECORD_SEPARATOR)[0]

    # Hostname: veos01
    # FQDN:     veos01.ztps-test.com

    hostname so.match(/Hostname:\s+(\w+)/)[1]
    machinename so.match(/Hostname:\s+(\w+)/)[1]
    fqdn so[1].match(/FQDN:\s+(\w+)/)[1]
    domain so[1].match(/FQDN:\s+(.*?\.)(.*)$/)[2]
  end
end
