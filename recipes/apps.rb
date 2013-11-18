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
  node.default['php-fpm']['pools'] = []
  node['rails']['apps'].each do |k, a|
    directory "#{node['rails']['base_path']}/#{a["name"]}" do
      owner a["user"]
      group a["user"]
      mode "0755"
      action :create
      recursive true
    end

    #set ruby
    unless a["rbenv"]["version"].include? node['rails']['rbenv']['version']
      rbenv_ruby "#{a["rbenv"]["version"]}" do
        ruby_version "#{a["rbenv"]["version"]}"
      end      
    end

    #add gems
    a["rbenv"]["gems"].each do |g|
      rbenv_gem "#{g}" do
        ruby_version "#{a["rbenv"]["version"]}"
      end
    end

    if node['mysql']['server_root_password']
      mysql_connection_info = {
        :host     => 'localhost',
        :username => 'root',
        :password => node['mysql']['server_root_password']
      }
    end
    if node['postgresql']['config']['port']
      postgresql_connection_info = {
        :host     => '127.0.0.1',
        :port     => node['postgresql']['config']['port'],
        :username => 'postgres',
        :password => node['postgresql']['password']['postgres']
      }
    end

    if a.include? "db"
      a["db"].each do |d|
        case d["type"]
        when "mongodb"
          if !File.exist?("mongo")
            include_recipe "mongodb::default"          
          end
          execute d["name"] do
            command "mongo #{d["name"]} --eval 'db.addUser(\"#{d["user"]}\",\"#{d["password"]}\")'"
            action :run
          end        
        when "postgresql"
          if !File.exist?("pg")
            include_recipe "postgresql::server"
          end
          include_recipe "postgresql::config_initdb"
          include_recipe "postgresql::config_pgtune"          
          include_recipe "postgresql::ruby"

          postgresql_database_user d["user"] do
            connection postgresql_connection_info
            password   d["password"]
            action     :create
          end
          postgresql_database d["name"] do
            connection postgresql_connection_info
            owner d["user"]            
            connection_limit '-1'
            action     :create       
          end
          # postgresql_database_user d["user"] do
          #   connection postgresql_connection_info
          #   database_name d["name"]
          #   privileges [:all]#:create,:delete,:execute,:truncate,:references,:trigger,:usage,:temp,:temporary]
          #   action     :grant
          # end
        when "mysql"
          if !File.exist?("mysqld")
            include_recipe "mysql::client"
            include_recipe "mysql::server"
          end
          include_recipe "mysql::ruby"
          mysql_database_user d["user"] do
            connection mysql_connection_info
            password   d["password"]
            action     :create
          end
          mysql_database d["name"] do
            connection mysql_connection_info
            owner d["user"]
            action :create
          end
          mysql_database_user d["user"] do
            connection    mysql_connection_info
            password      d["password"]
            database_name d["name"]
            privileges    [:all]
            action        :grant
          end

        end        
      end
    end

    if a.include? "php"
      node.default['php-fpm']['pools'].push(a["name"])
      node.default['php-fpm']['pool'][a["name"]]['listen'] = "/var/run/php-fpm-#{a["name"]}.sock"
      node.default['php-fpm']['pool'][a["name"]]['allowed_clients'] = ["127.0.0.1"]
      node.default['php-fpm']['pool'][a["name"]]['user'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['group'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['process_manager'] = "dynamic"
      node.default['php-fpm']['pool'][a["name"]]['max_children'] = 50
      node.default['php-fpm']['pool'][a["name"]]['start_servers'] = 5
      node.default['php-fpm']['pool'][a["name"]]['min_spare_servers'] = 5
      node.default['php-fpm']['pool'][a["name"]]['max_spare_servers'] = 35
      node.default['php-fpm']['pool'][a["name"]]['max_requests'] = 500
      node.default['php-fpm']['pool'][a["name"]]['catch_workers_output'] = "no"
      include_recipe "php"
      include_recipe "php-fpm"
    end
  end
end