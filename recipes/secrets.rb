#
# Cookbook Name:: rails
# Recipe:: secrets
#
# Copyright (C) 2013 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if(Gem.const_defined?("Version") and Gem::Version.new(Chef::VERSION) < Gem::Version.new('10.12.0'))
  gem_package 'chef-vault' do
    action :nothing
  end.run_action(:install)
  Gem.clear_paths
else
  chef_gem 'chef-vault' do
    action :nothing
  end.run_action(:install)
end

ruby_block "secrets" do
  block do
    require 'rubygems'
    require 'chef-vault'
    if Class.const_defined? "ChefVault"
      Chef::DataBag.load("secrets").each do |item|
        unless item[0].include? "_keys"
          key = ChefVault::Item.load("secrets", item[0])
          Chef::Provider::File "/etc/chef/#{key["file-name"]}" do
            content "#{key['file-content']}"
            owner   "root"
            group   "root"
            mode    "0600"
            action  :create
          end
          # File.open("/etc/chef/#{key["file-name"]}","w") do |f|
          #   f.write("#{key['file-content']}")
          #   f.chmod(0600)
          #   f.chown(0,0)
          # end
        end
      end
    end
  end
  action :nothing
end.run_action(:create)
