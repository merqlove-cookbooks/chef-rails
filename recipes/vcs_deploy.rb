#
# Cookbook Name:: rails
# Recipe:: vcs_deploy
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

chef_gem 'chef-vault'
require 'chef-vault'

puts "Deploy key on Github."
begin
  key = ChefVault::Item.load('tokens','github')
  # file "github" do
  #   path  "/home/#{node['rails']['user']['main']}/.ssh"
  #   owner 'root'
  #   group 'root'
  #   mode '0444'
  #   content item['file-content']
  # end
  deploy_key "github_key" do
    provider Chef::Provider::DeployKeyGithub
    path "/home/#{node['rails']['user']['main']}/.ssh" 
    credentials({
      :token => key['secret']
    })
    repo 'organization/million_dollar_app'
    owner node['rails']['user']['main']
    group node['rails']['user']['main']
    mode 00640
    action :add
  end
rescue ChefVault::Exceptions::KeysNotFound
  raise ChefVault::Exceptions::ItemNotFound,
    "Key not found at tokens/github!"
end

puts "Deploy key on BitBucket."
begin
  key = ChefVault::Item.load('tokens','bitbucket')
  # file "github" do
  #   path  "/home/#{node['rails']['user']['main']}/.ssh"
  #   owner 'root'
  #   group 'root'
  #   mode '0444'
  #   content item['file-content']
  # end
  deploy_key "bitbucket_key" do
    provider Chef::Provider::DeployKeyBitBucket
    path "/home/#{node['rails']['user']['main']}/.ssh" 
    credentials({
      :token => key['secret']
    })
    repo 'organization/million_dollar_app'
    owner node['rails']['user']['main']
    group node['rails']['user']['main']
    mode 00640
    action :add
  end
rescue ChefVault::Exceptions::KeysNotFound
  raise ChefVault::Exceptions::ItemNotFound,
    "Key not found at tokens/github!"
end