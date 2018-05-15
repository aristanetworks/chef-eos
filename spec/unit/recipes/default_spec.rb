#
# Cookbook Name:: eos
# Spec:: default
#
# Copyright (c) 2016 Arista Networks, All Rights Reserved.

require 'spec_helper'

describe 'eos::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'fedora', version: '26')
      runner.converge(described_recipe)
    end

    before(:each) do
      cmd = '/usr/bin/FastCli -p 15 -c "show running-config" | grep unix-socket'
      stub_command(cmd).and_return(true)
      stub_command('test -S /var/run/command-api.sock').and_return(true)
    end

    it 'converges successfully with eAPI configured' do
      expect { chef_run }.to_not raise_error
    end

    it 'converges successfully with eAPI not configured' do
      cmd = '/usr/bin/FastCli -p 15 -c "show running-config" | grep unix-socket'
      stub_command(cmd).and_return(false)
      expect { chef_run }.to_not raise_error
    end

    it 'configures eAPI for unix-sockets when not detected' do
      cmd = '/usr/bin/FastCli -p 15 -c "show running-config" | grep unix-socket'
      stub_command(cmd).and_return(false)
      expect(chef_run).to run_execute('Enable eAPI')
    end

    it 'does not reconfigure eAPI for unix-sockets when detected' do
      expect(chef_run).to_not run_execute('Enable eAPI')
    end

    it 'ensures base chef files are persistent' do
      expect(chef_run).to create_directory('/persist/sys/chef').with(
        owner: 'root',
        group: 'root',
        mode: '0755'
      )
      expect(chef_run).to create_link('/etc/chef').with(
        to: '/persist/sys/chef'
      )
    end

    it 'installs rbeapi as a chef_gem' do
      expect(chef_run).to install_chef_gem('rbeapi')
    end

    it 'installs ohai plugins' do
      expect(chef_run).to create_ohai_plugin('eos')
      expect(chef_run).to create_ohai_plugin('eos_hostname')
      expect(chef_run).to create_ohai_plugin('eos_lldp_neighbors')
    end
  end
end
