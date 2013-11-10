#
# Cookbook Name:: rails
# Recipe:: vcs_keys
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

if node.recipes.include? "role[vagrant]"
  if node['rails']['secrets']['default']
    if File.exists? node['rails']['secrets']['default']
      directory "/home/vagrant/.ssh" do
        owner "vagrant"
        group "vagrant"
        mode 0700
      end
      
      vcs = data_bag("vcs_keys")
      default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")

      vcs.each do |item|
        key = Chef::EncryptedDataBagItem.load("vcs_keys", item, default_secret)

        file "/home/vagrant/.ssh/#{key["file-name"]}" do
          content key['file-content']
          owner "vagrant"
          group "vagrant"
          mode 0600
        end
      end
    end
  end
end