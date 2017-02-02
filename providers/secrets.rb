#
# Cookbook Name:: rails
# Provider:: secrets
#
# Copyright (C) 2014 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use_inline_resources

action :create do
  chef_gem 'chef-vault' do # ~FC009
    compile_time true if respond_to?(:compile_time)
    action :nothing
  end.run_action(:install)

  ruby_block 'secrets' do
    block do
      require 'rubygems'
      require 'chef-vault'
      return unless Class.const_defined? 'ChefVault'

      Chef::DataBag.load('secrets').each do |item|
        next unless item[0] == node['rails']['secrets']['key']

        key = ChefVault::Item.load('secrets', item[0])
        s = Chef::Resource::File.new(node['rails']['secrets']['default'], run_context)
        s.owner      'root'
        s.group      'root'
        s.mode       0o0600
        s.sensitive  true
        s.content    key['file-content']
        s.run_action :create
      end
    end
    action :nothing
  end.run_action(:create)

  new_resource.updated_by_last_action(true)
end
