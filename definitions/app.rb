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

    if a.include? "smtp"      
      node.default['msmtp']['accounts'][a['user']][a["name"]]= a[:smtp]
      node.default['msmtp']['accounts'][a['user']][a["name"]][:syslog] = "on"
    end 

    if node.role? "base_ruby"
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
    end

    if a.include? "db"
      default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
      a["db"].each do |d|
        case d["type"]
        when "mongodb"        
          admin = Chef::EncryptedDataBagItem.load("mongodb", "admin", default_secret)
          if !File.exist?("/usr/bin/mongo")
            include_recipe "mongodb::default"  
            auth = template node['mongodb']['dbconfig_file'] do
              cookbook node['mongodb']['template_cookbook']
              source node['mongodb']['dbconfig_file_template']
              group node['mongodb']['root_group']
              owner "root"
              mode "0644"
              variables({
                "auth" => true
              })
              action :nothing
              notifies :restart, "service[#{node[:mongodb][:instance_name]}]"
            end           
            execute "create-mongodb-root-user" do              
              command "mongo admin --eval 'db.addUser(\"#{admin["id"]}\",\"#{admin["password"]}\")'"
              action :run
              not_if "mongo admin --eval 'db.auth(\"#{admin["id"]}\",\"#{admin["password"]}\")' | grep -q ^1$"
              notifies :create, auth, :immediately
            end
            node.default["rails"]["databases"].push "mongodb"
            node.default["rails"]["databases"] = node.default["rails"]["databases"].uniq
          else
            service node[:mongodb][:instance_name] do
              [:enable, :start]
            end                   
          end          

          rails_db_yml "#{d["name"]}_#{d["type"]}" do  
            database_name d["name"]          
            database_user d["user"]
            database_password d["password"]
            type d["type"]
            port "#{node['mongodb']['config']['port']}"
            host node['mongodb']['config']['bind_ip']
            path "#{node['rails']["#{type}_base_path"]}/#{a["name"]}"
            owner a["user"]
            group a["user"]
            action :nothing
          end

          package "php-pecl-mongo" if a.include? "php"
          execute d["name"] do
            command "mongo admin -u #{admin["id"]} -p #{admin["password"]} --eval '#{d["name"]}=db.getSiblingDB(\"#{d["name"]}\"); #{d["name"]}.addUser(\"#{d["user"]}\",\"#{d["password"]}\")'"            
            action :run
            not_if "mongo #{d["name"]} --eval 'db.auth(\"#{d["user"]}\",\"#{d["password"]}\")' | grep -q ^1$"
            notifies :create, "rails_db_yml[#{d["name"]}_#{d["type"]}]", :immediately
          end     
        when "postgresql"          
          postgres = Chef::EncryptedDataBagItem.load("postgresql", 'postgres', default_secret)
          if postgres
            node.default['postgresql']['password']['postgres'] = postgres["password"]            
          end

          postgresql_connection_info = {
            :host     => '127.0.0.1',
            :port     => node['postgresql']['config']['port'],
            :username => 'postgres',
            :password => postgres["password"]
          }

          if !File.exist?("/usr/bin/psql")
            include_recipe "postgresql::server"
            node.default["rails"]["databases"].push "mysql"
            node.default["rails"]["databases"] = node.default["rails"]["databases"].uniq
          else
            service node['postgresql']['server']['service_name'] do
              action [:enable, :start]
            end            
          end

          rails_db_yml "#{d["name"]}_#{d["type"]}" do  
            database_name d["name"]          
            database_user d["user"]
            database_password d["password"]
            type d["type"]
            port "#{node['postgresql']['config']['port']}"
            host node['postgresql']['config']['listen_addresses']
            path "#{node['rails']["#{type}_base_path"]}/#{a["name"]}"
            owner a["user"]
            group a["user"]
            action :nothing
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
            notifies :create, "rails_db_yml[#{d["name"]}_#{d["type"]}]", :immediately
          end
        when "mysql"
          root = Chef::EncryptedDataBagItem.load("mysql", 'root', default_secret)
          if root
            node.normal['mysql']['server_debian_password'] = root["debian_password"]
            node.normal['mysql']['server_root_password']   = root["password"]
            node.normal['mysql']['server_repl_password']   = root["replication_password"]
          end

          mysql_connection_info = {
            :host     => 'localhost',
            :username => 'root',
            :password => root["password"]
          }

          if !File.exist?("/usr/bin/mysqladmin")
            include_recipe "mysql::client"
            include_recipe "mysql::server"
            node.default["rails"]["databases"].push "mysql"
            node.default["rails"]["databases"] = node.default["rails"]["databases"].uniq
          end
          
          rails_db_yml "#{d["name"]}_#{d["type"]}" do  
            database_name d["name"]          
            database_user d["user"]
            database_password d["password"]
            type d["type"]
            port "#{node['mysql']['port']}"
            host node['mysql']['bind_address']
            path "#{node['rails']["#{type}_base_path"]}/#{a["name"]}"
            owner a["user"]
            group a["user"]
            action :nothing
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
            notifies :create, "rails_db_yml[#{d["name"]}_#{d["type"]}]", :immediately
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
      node.default['php-fpm']['pool'][a["name"]] = node['php-fpm']['default']['pool']

      node.default['php-fpm']['pool'][a["name"]]['listen'] = "/var/run/php-fpm-#{a["name"]}.sock"
      node.default['php-fpm']['pool'][a["name"]]['user'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['group'] = a["user"]
      node.default['php-fpm']['pool'][a["name"]]['session_save_path'] = "/var/lib/php/session/#{a["name"]}"      
      node.default['php-fpm']['pool'][a["name"]]['slowlog'] = "#{node['rails']["#{type}_base_path"]}/#{a["name"]}/log/php-fpm-slowlog.log"
      
      if a[:php][:pool]
        a[:php][:pool].each do |key, value|
          node.default['php-fpm']['pool'][a["name"]][:"#{key}"] = value
        end
      end
    
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
      if a.include? "smtp"
        node.default['msmtp']['accounts'][a['user']][a["name"]][:syslog] = "off"
        node.default['msmtp']['accounts'][a['user']][a["name"]][:log] = "#{node['rails']["#{type}_base_path"]}/#{a["name"]}/log/msmtp.log"        
        if a.include? "php"
          node.default['php-fpm']['pool'][a["name"]]['sendmail_path'] = "/usr/bin/msmtp -a #{a['name']} -t"
        end
      end
      server_name = a["nginx"]["server_name"].dup
      if node.role? "vagrant"
        server_name.push "#{a["nginx"]["vagrant_server_name"]}.#{node["vagrant"]["fqdn"]}" if a["nginx"]["vagrant_server_name"]
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
        server_name server_name
        path "#{node['rails']["#{type}_base_path"]}/#{a["name"]}"
        rewrites a["nginx"]["rewrites"]
        file_rewrites a["nginx"]["file_rewrites"]
        action :create
      end
    end 
  end
end