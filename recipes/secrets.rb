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

c = chef_gem 'chef-vault'
c.run_action(:install)

require 'chef-vault'

data_bag("secrets").each do |item|
  unless item.include? "_keys"
    key = ChefVault::Item.load("secrets", item)    

    f = file "#{key["file-name"]}" do
      path "/etc/chef/#{key["file-name"]}"
      owner "root"
      group "root"
      mode "0600"
      content "#{key['file-content']}"
    end
    f.run_action(:create)
  end
end

include_recipe "rails::users"
include_recipe "rails::vcs_keys"

