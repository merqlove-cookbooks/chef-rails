#
# Cookbook Name:: rails
# Recipe:: apps
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
  #Fix nginx
  file "#{node['nginx']['dir']}/conf.d/default.conf" do
    action :delete
  end  

  #PHP fpm fix
  node.default['php-fpm']['pools'] = []

  node['rails']['sites'].each do |k, a|
    app k do
      application a
      type "sites"
    end
  end

  node['rails']['apps'].each do |k, a|
    app k do
      application a
      type "apps"
    end
  end

  #PHP pools
  if node.default['php-fpm']['pools'].count > 0
    include_recipe "php-fpm"
    directory "/var/lib/php/session" do
      owner "root"
      group "root"
      mode "0777"      
    end
  end
end