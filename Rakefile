require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'foodcritic'
require 'kitchen'
require 'stove/rake_task'

# Style tests. Rubocop and Foodcritic
namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef) do |t|
    t.options = {
      fail_tags: ['any']
    }
  end
end

desc 'Run all style checks'
task style: ['style:ruby', 'style:chef']

desc 'Run ChefSpec examples'
RSpec::Core::RakeTask.new(:unit) do |t|
  t.pattern = './**/unit/**/*_spec.rb'
end

desc 'Run Test Kitchen - all combinations'
task :integration do
  Kitchen.logger = Kitchen.default_file_logger
  Kitchen::Config.new.instances.each do |instance|
    instance.test(:always)
  end
end

desc 'Run Test Kitchen on latest vEOS'
task :integration_latest do
  Kitchen.logger = Kitchen.default_file_logger
  Kitchen::Config.new.instances.get_all(/4171F/).each do |instance|
    instance.test(:always)
  end
end

Stove::RakeTask.new

# Default
task default: %w(style unit)

task full: %w(style unit integration)
