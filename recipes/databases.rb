#
# Cookbook Name:: rails
# Definition:: databases
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

default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")

if node.default["rails"]["databases"].include? "mongodb"
  admin = Chef::EncryptedDataBagItem.load("mongodb", "admin", default_secret)
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

  package "php-pecl-mongo" if FileTest.exist?("/usr/bin/php")

  node.default["rails"]["databases"]["mongodb"].each do |k,d|
    rails_db_yml "#{d["name"]}_mongodb" do  
      database_name d["name"]          
      database_user d["user"]
      database_password d["password"]
      type "mongodb"
      port "#{node['mongodb']['config']['port']}"
      host node['mongodb']['config']['bind_ip']
      path "#{node['rails']["#{d["app_type"]}_base_path"]}/#{d["app_name"]}"
      owner d["app_user"]
      group d["app_user"]
      action :nothing
    end

    execute d["name"] do
      command "mongo admin -u #{admin["id"]} -p #{admin["password"]} --eval '#{d["name"]}=db.getSiblingDB(\"#{d["name"]}\"); #{d["name"]}.addUser(\"#{d["user"]}\",\"#{d["password"]}\")'"            
      action :run
      not_if "mongo #{d["name"]} --eval 'db.auth(\"#{d["user"]}\",\"#{d["password"]}\")' | grep -q ^1$"
      notifies :create, "rails_db_yml[#{d["name"]}_mongodb]", :immediately
    end  
  end
end  

if node.default["rails"]["databases"].include? "postgresql"          
  postgres = Chef::EncryptedDataBagItem.load("postgresql", 'postgres', default_secret)
  node.normal['postgresql']['password']['postgres'] = postgres["password"]

  include_recipe "postgresql::server"            
  
  package "php-postgresql" if FileTest.exist?("/usr/bin/php")

  include_recipe "postgresql::config_initdb"
  include_recipe "postgresql::config_pgtune"

  include_recipe "postgresql::ruby"

  postgresql_connection_info = {
    :host     => '127.0.0.1',
    :port     => node['postgresql']['config']['port'],
    :username => 'postgres',
    :password => postgres["password"]
  }
  
  node.default["rails"]["databases"]["postgresql"].each do |k,d|
    rails_db_yml "#{d["name"]}_postgresql" do  
      database_name d["name"]          
      database_user d["user"]
      database_password d["password"]
      type "postgresql"
      port "#{node['postgresql']['config']['port']}"
      host node['postgresql']['config']['listen_addresses']
      path "#{node['rails']["#{d["app_type"]}_base_path"]}/#{d["app_name"]}"
      owner d["app_user"]
      group d["app_user"]
      action :nothing
    end

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
      notifies :create, "rails_db_yml[#{d["name"]}_postgresql]", :immediately
    end
  end  
end

if node.default["rails"]["databases"].include? "mysql"
  root = Chef::EncryptedDataBagItem.load("mysql", 'root', default_secret)
  if root
    node.normal['mysql']['server_debian_password'] = root["debian_password"]
    node.normal['mysql']['server_root_password']   = root["password"]
    node.normal['mysql']['server_repl_password']   = root["replication_password"]
  end

  include_recipe "mysql::client"
  include_recipe "mysql::server"            
  
  package "php-mysql" if FileTest.exist?("/usr/bin/php")
  include_recipe "mysql::ruby"  

  mysql_connection_info = {
    :host     => 'localhost',
    :username => 'root',
    :password => root["password"]
  }

  node.default["rails"]["databases"]["mysql"].each do |k,d|
    rails_db_yml "#{d["name"]}_mysql" do  
      database_name d["name"]          
      database_user d["user"]
      database_password d["password"]
      type "mysql"
      port "#{node['mysql']['port']}"
      host node['mysql']['bind_address']
      path "#{node['rails']["#{d["app_type"]}_base_path"]}/#{d["app_name"]}"
      owner d["app_user"]
      group d["app_user"]
      action :nothing
    end

    mysql_database_user d["user"] do
      connection mysql_connection_info
      password   d["password"]
      action     :create
    end          

    mysql_database d["name"] do
      connection mysql_connection_info
      owner d["user"]
      action :create
      notifies :create, "rails_db_yml[#{d["name"]}_mysql]", :immediately
      notifies :grant, "mysql_database_user[grant_#{d["user"]}_#{d["name"]}]", :immediately
    end
    mysql_database_user "grant_#{d["user"]}_#{d["name"]}" do
      username  d["user"]
      connection    mysql_connection_info
      password      d["password"]
      database_name d["name"]
      privileges    [:all]
      action        :nothing
    end
  end  
end
