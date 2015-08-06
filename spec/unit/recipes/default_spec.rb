#
# Cookbook Name:: nginx-wrapper
# Spec:: default
#
# Copyright (c) 2015 Alexander Merkulov, All Rights Reserved.

require 'spec_helper'

describe 'rails::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.default['postgresql']['version'] = '9.4'
        node.automatic['ipaddress'] = '500.500.500.500' # Intentionally not a real IP
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      stub_command('ls /recovery.conf')
      chef_run
    end

    it 'has attributes' do
      stub_command('ls /recovery.conf')
      expect(chef_run).to install_package('postgresql')
    end
  end
end
