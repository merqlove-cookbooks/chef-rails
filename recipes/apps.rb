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

#Fix nginx
file "#{node['nginx']['dir']}/conf.d/default.conf" do
  action :delete
end  

#PHP fpm fix
node.default['php-fpm']['pools'] = []

#Useful databases
node.default["rails"]["databases"] = []

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
  
  if Dir.exist? "#{node['php-fpm']['conf_dir']}/pools"
    deleted = false
    Dir.foreach("#{node['php-fpm']['conf_dir']}/pools") do |pool|
      next if pool == '.' or pool == '..'
      if pool.include? ".conf"
        unless node['php-fpm']['pools'].include? pool.gsub(/\.conf/, '')
          File.delete("#{node['php-fpm']['conf_dir']}/pools/#{pool}") 
          deleted = true
        end
      end
    end

    service node['php-fpm']['service'] do
      action :restart
      only_if { deleted }
    end      
  end

  directory "/var/lib/php/session" do
    owner "root"
    group "root"
    mode "0777"      
  end
else
  if Dir.exist? "#{node['php-fpm']['conf_dir']}/pools"  
    Dir.foreach("#{node['php-fpm']['conf_dir']}/pools") do |pool|
      next if pool == '.' or pool == '..'
      if pool.include? ".conf"
        File.delete("#{node['php-fpm']['conf_dir']}/pools/#{pool}")
      end
    end
    service node['php-fpm']['service'] do
      action [:disable, :stop]
    end
  end
end