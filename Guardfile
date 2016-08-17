# Enable guards with the following:
#   chef gem install guard-foodcritic
#   chef exec guard

guard 'foodcritic', cookbook_paths: '.', all_on_start: false do
  watch(%r{attributes/.+\.rb$})
  watch(%r{providers/.+\.rb$})
  watch(%r{recipes/.+\.rb$})
  watch(%r{resources/.+\.rb$})
  watch(%r{templates/.+$})
  watch('metadata.rb')
end
