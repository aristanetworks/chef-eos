#
# Copyright 2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'bundler/setup'

require 'rbeapi'
require 'chefspec'
require 'chefspec/berkshelf'

# load all library files for easy mocking
libs = File.expand_path('../libraries', __dir__)
$LOAD_PATH.unshift(libs) unless $LOAD_PATH.include?(libs)
Dir[File.join(libs, '*.rb')].each do |lib|
  require File.basename(lib, '.rb')
end

RSpec.configure do |config|
  # Specify the Chef log_level (default: :warn)
  config.log_level = :error

  # Use color in STDOUT
  config.color = true

  config.formatter = :documentation # :progress, :html, :textmate

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

RSpec::Matchers.define :have_constant do |const|
  match do |owner|
    owner.const_defined?(const)
  end
end

at_exit { ChefSpec::Coverage.report! }
