#
# Cookbook Name:: rails
# Recipe:: users
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

if node['rails']['apps']
  users = node['rails']['apps'].map do |a|
    a["user"]
  end.compact
  
  if File.exists? node['rails']['secrets']['default']
    default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
    vcs = data_bag("vcs_keys")

    users.each do |u|
      data = Chef::EncryptedDataBagItem.load('users', u, default_secret)
      if data
        user u do
          home      "/home/#{u}"
          shell     data["shell"]
          groups    data["groups"].push("rbenv")
          comment   data["comment"]
          supports  :manage_home => true
        end

        directory "/home/#{u}/.ssh" do
          action :create
          owner  u
          group  u
          mode   '0700'
        end

        template "/home/#{u}/.ssh/authorized_keys" do
          source 'authorized_keys.erb'
          owner  u
          group  u
          mode  '0600'
          variables :keys => data["ssh_keys"]
        end

        if data["vcs"]
          data["vcs"].each do |v|
            if vcs.include? v
              key = Chef::EncryptedDataBagItem.load("vcs_keys", v, default_secret)

              file "/home/vagrant/.ssh/#{key["file-name"]}" do
                content key['file-content']
                owner u
                group u
                mode 0600
              end
            end
          end
        end

      end
    end

  end
end