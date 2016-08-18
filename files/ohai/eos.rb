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
#
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
