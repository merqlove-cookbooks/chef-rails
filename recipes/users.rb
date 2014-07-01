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

if node['rails']['apps'] or node['rails']['sites']
  app_users = []
  site_users = []
  node['rails']['apps'].each do |k, a|
    app_users.push a["user"]
  end
  node['rails']['sites'].each do |k, a|
    site_users.push a["user"]    
  end
  app_users = app_users.push(node['rails']['user']['deploy']).uniq.compact
  site_users = site_users.uniq.compact
  
  if File.exists?(node['rails']['secrets']['default']) and Chef.const_defined?("EncryptedDataBagItem")
    default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
    vcs = data_bag("vcs_keys")

    user_ref "references_for_site_users" do
      users site_users
      secret default_secret
      vcs vcs
      type "sites"
    end

    user_ref "references_for_app_users" do
      users app_users
      secret default_secret
      vcs vcs
    end

    #Reload OHAI 7
    ohai "reload_passwd" do
      action :nothing
      plugin "etc"
    end
  end
end
