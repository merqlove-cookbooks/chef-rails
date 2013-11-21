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

# if File.exist? "mysqladmin"
#   include_recipe "mysql::ruby"
#   mysql_connection_info = {
#     :host     => 'localhost',
#     :username => 'root',
#     :password => node['mysql']['server_root_password']
#   }
#   mysql_database_user 'admin' do
#     connection mysql_connection_info
#     password   node['mysql']['server_root_password']
#     action     [:create, :grant]
#   end
# end

if File.exist? "/usr/bin/psql"

  postgresql_connection_info = {
    :host     => '127.0.0.1',
    :port     => node['postgresql']['config']['port'],
    :username => 'postgres',
    :password => node['postgresql']['password']['postgres']
  }

  postgresql_database "template1" do
    connection postgresql_connection_info
    sql <<-EOH
    DO
    $body$
    BEGIN
       IF NOT EXISTS (
          SELECT *
          FROM   pg_catalog.pg_user
          WHERE  usename = 'admin') THEN

          CREATE ROLE admin WITH SUPERUSER LOGIN CREATEDB REPLICATION PASSWORD '#{node['postgresql']['password']['admin']}';
       END IF;
    END
    $body$
    EOH
    action     :query
  end
end

if File.exist? "/usr/bin/mongo"

  execute "create-mongodb-root-user" do
    command "mongo admin --eval 'db.addUser(\"admin\",\"#{node['postgresql']['password']['postgres']}\")'"
    action :run
    not_if "mongo admin --eval 'db.auth(\"admin\",\"#{node['postgresql']['password']['postgres']}\")' | grep -q ^1$"
  end
end