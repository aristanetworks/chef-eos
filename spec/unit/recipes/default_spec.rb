#
# Cookbook Name:: eos
# Spec:: default
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

require 'spec_helper'

describe 'eos::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.converge(described_recipe)
    end

    it 'converges successfully with eAPI configured' do
      stub_command("/usr/bin/FastCli -p 15 -c \"show running-config\" | grep unix-socket").and_return(true)
      expect { chef_run }.to_not raise_error
    end

    it 'converges successfully with eAPI not configured' do
      stub_command("/usr/bin/FastCli -p 15 -c \"show running-config\" | grep unix-socket").and_return(false)
      expect { chef_run }.to_not raise_error
    end

    it 'configures eAPI for unix-sockets when not detected' do
      stub_command("/usr/bin/FastCli -p 15 -c \"show running-config\" | grep unix-socket").and_return(false)
      expect(chef_run).to run_execute('Enable eAPI')
    end

    it 'does not reconfigure eAPI for unix-sockets when detected' do
      stub_command("/usr/bin/FastCli -p 15 -c \"show running-config\" | grep unix-socket").and_return(true)
      expect(chef_run).to_not run_execute('Enable eAPI')
    end

    it 'ensures base chef files are persistent' do
      stub_command("/usr/bin/FastCli -p 15 -c \"show running-config\" | grep unix-socket").and_return(true)
      expect(chef_run).to create_directory('/persist/sys/chef').with(
        owner: 'root',
        group: 'root',
        mode: '0755'
      )
      expect(chef_run).to create_link('/etc/chef').with(
        to: '/persist/sys/chef'
      )
    end
  end
end
