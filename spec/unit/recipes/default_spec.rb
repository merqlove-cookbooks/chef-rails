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
        node.automatic['ipaddress'] = '500.500.500.500' # Intentionally not a real IP
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      stub_command('ls /recovery.conf')
      chef_run
    end
  end
end
