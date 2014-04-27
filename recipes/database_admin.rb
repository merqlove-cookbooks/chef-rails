#
# Cookbook Name:: rails
# Recipe:: database_admin
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

if File.exist? "/usr/bin/mysqladmin" and node.default["rails"]["databases"].include? "mysql"
  mysql = data_bag("mysql")
  if mysql
    root = Chef::EncryptedDataBagItem.load("mysql", 'root', default_secret)
    mysql_connection_info = {
      :host     => 'localhost',
      :username => root['id'],
      :password => root["password"]
    }   

    include_recipe "database::mysql"
    (mysql-["root"]).each do |m|
      u = Chef::EncryptedDataBagItem.load("mysql", m, default_secret)
      mysql_database_user u["id"] do
        connection mysql_connection_info
        password   u["password"]
        action     [:create, :grant]
      end
    end
  end  
end

if File.exist? "/usr/bin/psql" and node.default["rails"]["databases"].include? "postgresql"
  psql = data_bag("postgresql")
  if psql
    postgres = Chef::EncryptedDataBagItem.load("postgresql", 'postgres', default_secret)
    postgresql_connection_info = {
      :host     => '127.0.0.1',
      :port     => node['postgresql']['config']['port'],
      :username => postgres["id"],
      :password => postgres["password"]
    }
    (psql-["postgres"]).each do |p|
      u = Chef::EncryptedDataBagItem.load("postgresql", p, default_secret)
      postgresql_database "template1" do
        connection postgresql_connection_info
        sql <<-EOH
        DO
        $body$
        BEGIN
           IF NOT EXISTS (
              SELECT *
              FROM   pg_catalog.pg_user
              WHERE  usename = '#{u["id"]}') 
           THEN
              CREATE ROLE #{u["id"]} WITH SUPERUSER LOGIN CREATEDB REPLICATION PASSWORD '#{u["password"]}';
           ELSE
              ALTER ROLE #{u["id"]} WITH SUPERUSER LOGIN CREATEDB REPLICATION PASSWORD '#{u["password"]}';   
           END IF;
        END
        $body$
        EOH
        action :query
      end
    end
  end
end

if File.exist? "/usr/bin/mongo" and node.default["rails"]["databases"].include? "mongodb"
  mongo = data_bag("mongodb")
  if mongo
    admin = Chef::EncryptedDataBagItem.load("mongodb", "admin", default_secret)
    (mongo-["admin"]).each do |m|
      u = Chef::EncryptedDataBagItem.load("mongodb", m, default_secret)
      execute "create-mongodb-admin-user" do
        command "mongo admin -u #{admin["id"]} -p #{admin["password"]} --eval 'db.addUser(\"#{u["id"]}\",\"#{u["password"]}\")'"
        action :run
        not_if "mongo admin --eval 'db.auth(\"#{u["id"]}\",\"#{u["password"]}\")' | grep -q ^1$"
      end
    end
  end
end