require 'spec_helper'
# Serverspec examples can be found at
# http://serverspec.org/resource_types.html

describe 'eos::default' do
  #it 'creates a link from /etc/chef to /persist/sys/chef' do
  #skip 'Replace this with meaningful tests'

  describe file('/persist/sys/chef') do
    it { should be_directory }
    it { should be_mode 755 }
  end

  describe file('/etc/chef') do
    it { should be_symlink }
    it { should be_linked_to '/persist/sys/chef' }
  end

  describe command('/usr/bin/FastCli -p 15 -c "show running-config section management api http-commands"') do
    its(:stdout) { should contain('protocol unix-socket')}
    its(:stdout) { should contain('no shutdown')}
  end
end
