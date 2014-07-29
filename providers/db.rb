#
# Cookbook Name:: rails
# Provider:: db
#
# Copyright (C) 2014 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'

::Chef::Provider.send(:include, Rails::Helpers)

action :create do
  secret = new_resource.secret
  date   = new_resource.date

  if database_type_exist? 'mysql'
    create_mysql_dbs(secret, date)
  else
    stop_mysql
  end

  if database_type_exist? 'postgresql'
    create_postgresql_dbs(secret, date)
  else
    stop_postgresql
  end

  if database_type_exist? 'mongodb'
    create_mongodb_dbs(secret, date)
  else
    stop_mongodb
  end

  new_resource.updated_by_last_action(true)
end

# Makers

def create_mysql_dbs(secret, date) # rubocop:disable Style/MethodLength
  root = ::Chef::EncryptedDataBagItem.load('mysql', 'root', secret)
  if root
    node.normal['mysql']['server_debian_password'] = root['debian_password']
    node.normal['mysql']['server_root_password']   = root['password']
    node.normal['mysql']['server_repl_password']   = root['replication_password']
  end

  install_mysql

  mysql_connection_info = {
    host:     'localhost',
    username: 'root',
    password: root['password']
  }

  node['rails']['databases']['mysql'].each do |_k, d|
    backup_mysql_db(d, date, root['password'])

    next if d['app_delete']

    rails_db_yml        "#{d['name']}_mysql" do
      database_name     d['name']
      database_user     d['user']
      database_password d['password']
      type              'mysql'
      port              node['mysql']['port']
      host              node['mysql']['bind_address']
      path              d['app_path']
      owner             d['app_user']
      group             d['app_user']
      action            :create
    end

    mysql_database_user d['user'] do
      connection mysql_connection_info
      password   d['password']
      action     :create
    end

    mysql_database d['name'] do
      connection mysql_connection_info
      owner      d['user']
      action     :create
      notifies   :grant, "mysql_database_user[grant_#{d['user']}_#{d['name']}]", :immediately
    end
    mysql_database_user "grant_#{d['user']}_#{d['name']}" do
      username      d['user']
      connection    mysql_connection_info
      password      d['password']
      database_name d['name']
      privileges    [:all]
      action        :nothing
    end
  end

  create_mysql_admin(secret, root)
end

def install_mysql # rubocop:disable Style/MethodLength
  run_context.include_recipe 'mysql::server'
  run_context.include_recipe 'mysql::client'

  service node['rails']['mysqld']['service_name'] do
    supports status: true, restart: true, reload: true, start: true, stop: true
    action :nothing
  end

  tune_mysql

  run_context.include_recipe 'database::mysql'

  if php? # rubocop:disable Style/GuardClause
    case node['platform_family']
    when 'rhel'
      package 'php-mysqlnd'
    when 'ubuntu'
      package 'php5-mysqlnd'
    end
  end
end

def tune_mysql # rubocop:disable Style/MethodLength
  ruby_block 'cleanup_innodb_logfiles' do
    block do
      ::Dir.glob("#{node['mysql']['data_dir']}/ib*").each do |f|
        next if f == '.' || f == '..' || ::File.directory?(f)
        ::File.delete(f) if f.include?('ib_logfile') || f.include?('ibdata')
      end
    end
    action :nothing
    notifies :start, "service[#{node['rails']['mysqld']['service_name']}]", :immediately
  end

  template "#{node['rails']['mysqld']['include_dir']}/tune.cnf" do
    owner    'mysql'
    owner    'mysql'
    source   'mysql_tune.cnf.erb'
    variables(
        config: node['rails']['mysql']
    )
    notifies :stop, "service[#{node['rails']['mysqld']['service_name']}]", :immediately
    notifies :run, 'ruby_block[cleanup_innodb_logfiles]', :immediately
  end
end

def create_mysql_admin(secret, root) # rubocop:disable Style/MethodLength
  return unless secret && root
  mysql = data_bag('mysql')
  return unless mysql

  mysql_connection_info = {
    host:     'localhost',
    username: root['id'],
    password: root['password']
  }

  (mysql - ['root']).each do |m|
    u = ::Chef::EncryptedDataBagItem.load('mysql', m, secret)
    mysql_database_user u['id'] do
      connection mysql_connection_info
      password   u['password']
      action     [:create, :grant]
    end
  end
end

def backup_mysql_db(d, date, password) # rubocop:disable Style/MethodLength,Style/CyclomaticComplexity
  return unless d && date && password

  exec_before = [
    "mysqldump -u root -p#{password} #{d['name']} | gzip > #{d['app_backup_dir']}/#{d['name']}.$NOW.sql.gz"
  ]

  backup_db('mysql', d, date, exec_before)
end

def stop_mysql
  mysql_init = ::File.join('/etc/init.d', node['rails']['mysqld']['service_name'])
  service node['rails']['mysqld']['service_name'] do
    action [:stop, :disable]
    only_if { ::FileTest.file? mysql_init }
  end
end

def create_postgresql_dbs(secret, date) # rubocop:disable Style/MethodLength
  postgres = ::Chef::EncryptedDataBagItem.load('postgresql', 'postgres', secret)
  node.normal['postgresql']['password']['postgres'] = postgres['password']

  install_postgresql

  template '/root/.pgpass' do
    source 'pgpass.erb'
    variables(
        password: postgres['password']
    )
    group  'root'
    user   'root'
    mode   00600
    action :delete
  end

  postgresql_connection_info = {
    host:     '127.0.0.1',
    port:     node['postgresql']['config']['port'],
    username: 'postgres',
    password: postgres['password']
  }

  node['rails']['databases']['postgresql'].each do |_k, d|
    backup_postgresql_db(d, date)

    next if d['app_delete']

    rails_db_yml        "#{d['name']}_postgresql" do
      database_name     d['name']
      database_user     d['user']
      database_password d['password']
      type              'postgresql'
      pool              d['pool']
      port              node['postgresql']['config']['port']
      host              node['postgresql']['config']['listen_addresses']
      path              d['app_path']
      owner             d['app_user']
      group             d['app_user']
      action            :create
    end

    postgresql_database_user d['user'] do
      connection postgresql_connection_info
      password   d['password']
      action     :create
    end

    postgresql_database d['name'] do
      connection       postgresql_connection_info
      owner            d['user']
      connection_limit '-1'
      action           :create
    end
  end

  create_postgresql_admin(secret, postgres)
end

def create_postgresql_admin(secret, postgres) # rubocop:disable Style/MethodLength
  return unless secret && postgres
  psql = data_bag('postgresql')
  return unless psql

  postgresql_connection_info = {
    host:     '127.0.0.1',
    port:     node['postgresql']['config']['port'],
    username: postgres['id'],
    password: postgres['password']
  }
  (psql - ['postgres']).each do |p|
    u = ::Chef::EncryptedDataBagItem.load('postgresql', p, secret)
    postgresql_database 'template1' do
      connection postgresql_connection_info
      sql <<-EOH
      DO
      $body$
      BEGIN
         IF NOT EXISTS (
            SELECT *
            FROM   pg_catalog.pg_user
            WHERE  usename = '#{u['id']}')
         THEN
            CREATE ROLE #{u['id']} WITH SUPERUSER LOGIN CREATEDB REPLICATION PASSWORD '#{u['password']}';
         ELSE
            ALTER ROLE #{u['id']} WITH SUPERUSER LOGIN CREATEDB REPLICATION PASSWORD '#{u['password']}';
         END IF;
      END
      $body$
      EOH
      action :query
    end
  end
end

def install_postgresql # rubocop:disable Style/MethodLength
  case node['platform_family']
  when 'debian'
    node.default['postgresql']['enable_pgdg_apt'] = true
  when 'rhel', 'fedora', 'suse'
    node.default['postgresql']['enable_pgdg_yum'] = true
  end

  run_context.include_recipe 'postgresql::contrib'

  if php?
    case node['platform_family']
    when 'rhel'
      package 'php-postgresql'
    when 'debian'
      package 'php5-pgsql'
    end
  end

  run_context.include_recipe 'postgresql::config_initdb'
  run_context.include_recipe 'postgresql::config_pgtune'

  run_context.include_recipe 'postgresql::ruby'
end

def backup_postgresql_db(d, date) # rubocop:disable Style/MethodLength
  return unless d && date

  exec_before = [
    "su postgres -c 'pg_dump -U postgres #{d['name']} | gzip > /tmp/#{d['name']}.\"$0\".sql.gz' -- \"$NOW\"",
    "mv /tmp/#{d['name']}.$NOW.sql.gz #{d['app_backup_dir']}/",
    "chown -R #{d['app_user']}:#{d['app_user']} #{d['app_backup_dir']}/*"
  ]

  backup_db('pg', d, date, exec_before)
end

def stop_postgresql
  postgresql_init = ::File.join('/etc/init.d', node['postgresql']['server']['service_name'])
  service node['postgresql']['server']['service_name'] do
    action [:stop, :disable]
    only_if { ::FileTest.file? postgresql_init }
  end
end

def create_mongodb_dbs(secret, date) # rubocop:disable Style/MethodLength
  admin = ::Chef::EncryptedDataBagItem.load('mongodb', 'admin', secret)
  run_context.include_recipe 'mongodb::default'
  node.default['mongodb']['config']['auth'] = true if node['rails']['mongodb']['auth']

  chef_gem 'mongo'

  mongodb_user admin['id'] do
    password   admin['password']
    roles      %w(userAdminAnyDatabase dbAdminAnyDatabase)
    database   'admin'
    connection node['mongodb']
    action     :add
  end

  if php?
    case node['platform_family']
    when 'rhel'
      package 'php-pecl-mongo'
    when 'debian'
      package 'php5-mongo'
    end
  end

  node['rails']['databases']['mongodb'].each do |_k, d|
    backup_mongodb_db(d, date)

    next if d['app_delete']

    rails_db_yml "#{d['name']}_mongodb" do
      database_name     d['name']
      database_user     d['user']
      database_password d['password']
      type              'mongodb'
      port              node['mongodb']['config']['port'].to_s
      host              node['mongodb']['config']['bind_ip']
      path              d['app_path']
      owner             d['app_user']
      group             d['app_user']
      action            :create
    end

    mongodb_user d['user'] do
      password   d['password']
      database   d['name']
      roles      %w(readWrite)
      connection node['mongodb']
      action     :add
    end
  end

  create_mongodb_admin(secret, admin)
end

def create_mongodb_admin(secret, admin) # rubocop:disable Style/MethodLength
  return unless secret && admin
  mongo = data_bag('mongodb')
  return unless mongo # rubocop:disable Style/BlockNesting

  (mongo - ['admin']).each do |m|
    u = ::Chef::EncryptedDataBagItem.load('mongodb', m, secret)

    mongodb_user u['id'] do
      password   u['password']
      roles      %w(userAdminAnyDatabase dbAdminAnyDatabase)
      database   'admin'
      connection node['mongodb']
      action     :add
    end
  end
end

def backup_mongodb_db(d, date) # rubocop:disable Style/MethodLength
  return unless d && date

  exec_before = [
    "mongodump --dbpath #{node['mongodb']['config']['dbpath']} --db #{d['name']} --out #{d['app_backup_dir']}/#{d['name']}.$NOW >> /dev/null 2>&1",
    "gzip #{d['app_backup_dir']}/#{d['name']}.$NOW",
    "rm -f #{d['app_backup_dir']}/#{d['name']}.$NOW"
  ]

  backup_db('mongo', d, date, exec_before)
end

def stop_mongodb
  mongo_init = ::File.join(node['mongodb']['init_dir'], node['mongodb']['instance_name'])
  service node['mongodb']['instance_name'] do
    action [:stop, :disable]
    only_if { ::FileTest.file? mongo_init }
  end
end

def backup_db(name, d, date, before = [], pre = [], after = []) # rubocop:disable Style/CyclomaticComplexity,Style/MethodLength,Style/ParameterLists
  return unless name && d && date

  if d['app_backup']
    rails_backup "#{name}_db_#{d['app_name']}" do
      path        d['app_backup_path']
      exec_pre    [
        "mkdir -p #{d['app_backup_dir']} >> /dev/null 2>&1",
      ].concat(pre)
      exec_before [
        date,
        "rm -rf #{d['app_backup_dir']}/*"
      ].concat(before)
      exec_after  [].concat(after)
      include     [d['app_backup_dir']]
      archive_dir d['app_backup_archive']
      temp_dir    d['app_backup_temp']
    end
  else
    rails_backup "delete #{name}_db_#{d['app_name']}" do
      name "#{name}_db_#{d['app_name']}"
      action :delete
    end
    ::FileUtils.remove_dir(d['app_backup_archive']) if ::Dir.exist? d['app_backup_archive'] # rubocop:disable Style/BlockNesting
    ::FileUtils.remove_dir(d['app_backup_temp']) if ::Dir.exist? d['app_backup_temp'] # rubocop:disable Style/BlockNesting
  end
end
