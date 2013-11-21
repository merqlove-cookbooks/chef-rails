#
# Cookbook Name:: rails
# Definition:: app
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
define :app, application: false, type: "apps" do
  if params[:application]
    a = params[:application]
    type = params[:type]

    directory "#{node['rails']["#{type}_base_path"]}/#{a["name"]}" do
      owner a["user"]
      group a["user"]
      mode "0750"
      recursive true
    end

    group a["user"] do
      append true
      members [node['nginx']['user']]
    end  

    if a.include? "rbenv"
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
    end

    if node['mysql']['server_root_password']
      mysql_connection_info = {
        :host     => 'localhost',
        :username => 'root',
        :password => node['mysql']['server_root_password']
      }
    end

    if node['postgresql']['password']['postgres']
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
          if !File.exist?("/usr/bin/mongo")
            include_recipe "mongodb::default"          
          end
          package "php-pecl-mongo" if a.include? "php"
          execute d["name"] do
            command "mongo #{d["name"]} --eval 'db.addUser(\"#{d["user"]}\",\"#{d["password"]}\")'"
            action :run
          end        
        when "postgresql"
          if !File.exist?("/usr/bin/psql")
            include_recipe "postgresql::server"
          end
          package "php-postgresql" if a.include? "php"
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
          if !File.exist?("/usr/bin/mysqladmin")
            include_recipe "mysql::client"
            include_recipe "mysql::server"
          end
          package "php-mysql" if a.include? "php"
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
      if !File.exist?("/usr/bin/php")
        include_recipe "php"          
        package "php-gd"
        package "php-pecl-memcached"
        package "php-pecl-apcu"
        package "php-mbstring" do
          action :install
          notifies :reload, 'service[php-fpm]', :delayed
        end
      end

      include_recipe "composer"

      directory "/var/lib/php/session/#{a["name"]}" do
        owner a["user"]
        group a["user"]
        mode "0700"
        action :create
        recursive true
      end
      
      template "/etc/php.d/php_fix.ini" do
        owner "root"
        group "root"
        mode '755'
        source 'php_fix.erb'
        notifies :reload, 'service[php-fpm]', :delayed
      end
      node.default['php-fpm']['pools'].push(a["name"])
      node.default['php-fpm']['pool'][a["name"]]['listen'] = "/var/run/php-fpm-#{a["name"]}.sock"
      node.default['php-fpm']['pool'][a["name"]]['allowed_clients'] = ["127.0.0.1"]
      node.default['php-fpm']['pool'][a["name"]]['user'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['group'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['process_manager'] = "dynamic"
      node.default['php-fpm']['pool'][a["name"]]['max_children'] = 4
      node.default['php-fpm']['pool'][a["name"]]['start_servers'] = 2
      node.default['php-fpm']['pool'][a["name"]]['min_spare_servers'] = 1
      node.default['php-fpm']['pool'][a["name"]]['max_spare_servers'] = 3
      node.default['php-fpm']['pool'][a["name"]]['max_requests'] = 200
      node.default['php-fpm']['pool'][a["name"]]['catch_workers_output'] = "no"      
      node.default['php-fpm']['pool'][a["name"]]['session_save_path'] = "/var/lib/php/session/#{a["name"]}"
      node.default['php-fpm']['pool'][a["name"]]['request_slowlog_timeout'] = "5s"
      node.default['php-fpm']['pool'][a["name"]]['slowlog'] = "#{node['rails']["#{type}_base_path"]}/#{a["name"]}/log/php-fpm-slowlog.log"
      node.default['php-fpm']['pool'][a["name"]]['backlog'] = "-1"
      node.default['php-fpm']['pool'][a["name"]]['rlimit_files'] = "131072"
      node.default['php-fpm']['pool'][a["name"]]['rlimit_core'] = "unlimited"
    end
    
    if type.include? "sites" and a.include? "nginx"
      directory "#{node['rails']["#{type}_base_path"]}/#{a["name"]}/docs" do
        mode      '0755'
        owner     a['user']
        group     a['user']
        action    :create
        recursive true
      end
      directory "#{node['rails']["#{type}_base_path"]}/#{a["name"]}/log" do
        mode      '0755'
        owner     a['user']
        group     a['user']
        action    :create
        recursive true
      end
      rails_nginx_vhost a["name"] do
        access_log a["nginx"]["access_log"]
        error_log a["nginx"]["error_log"]
        default a["nginx"]["default"] unless node.role? "vagrant"
        deferred a["nginx"]["deferred"] unless node.role? "vagrant"
        hidden a["nginx"]["hidden"]
        disable_www a["nginx"]["disable_www"]
        php a.include? "php"
        listen a["nginx"]["listen"]
        server_name a["nginx"]["server_name"]
        path "#{node['rails']["#{type}_base_path"]}/#{a["name"]}"
        rewrites a["nginx"]["rewrites"]
        file_rewrites a["nginx"]["file_rewrites"]
        action :create
      end
    end 
  end
end