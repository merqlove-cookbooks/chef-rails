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

if Chef.const_defined? "EncryptedDataBagItem"
  default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
  date = '$(date +"%Y%m%d")'

  # Backup Mongo User DB

  if node.default["rails"]["databases"].include?("mongodb")
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
        path d["app_path"]
        owner d["app_user"]
        group d["app_user"]
        action :create
      end

      if d["app_backup"]
        rails_backup "mongo_db_#{d["app_name"]}" do
          path        d["app_backup_path"]
          exec_pre    [
            "mkdir -p #{d["app_backup_dir"]} >> /dev/null 2>&1",
            "rm -rf #{d["app_backup_dir"]}/*",
            "mongodump --quiet --dbpath #{node['mongodb']['config']['dbpath']} --db #{d["name"]} --out #{d["app_backup_dir"]}/#{d["name"]}.#{date}",
            "bzip2 -c #{d["app_backup_dir"]}/#{d["name"]}.#{date} > #{d["app_backup_dir"]}/#{d["name"]}.#{date}.bz2",
            "rm -f #{d["app_backup_dir"]}/#{d["name"]}.#{date}"
          ]
          include     ["#{d["app_backup_dir"]}"]
          archive_dir d["app_backup_archive"]
          temp_dir    d["app_backup_temp"]
        end
      else
        rails_backup "mongo_db_#{d["app_name"]} delete" do
          action :delete
        end
        directory d["app_backup_archive"] do
          action :delete
        end
        directory d["app_backup_temp"] do
          action :delete
        end
      end

      execute d["name"] do
        command "mongo admin -u #{admin["id"]} -p #{admin["password"]} --eval '#{d["name"]}=db.getSiblingDB(\"#{d["name"]}\"); #{d["name"]}.addUser(\"#{d["user"]}\",\"#{d["password"]}\")'"
        action :run
        not_if "mongo #{d["name"]} --eval 'db.auth(\"#{d["user"]}\",\"#{d["password"]}\")' | grep -q ^1$"
      end
    end
  else
    mongo_init = File.join(node[:mongodb][:init_dir], node['mongodb']['instance_name'])
    if FileTest.file? mongo_init
      service node['mongodb']['instance_name'] do
        action [:stop, :disable]
      end
    end
  end

  # Backup Postgresql User DB

  if node.default["rails"]["databases"].include?("postgresql")
    postgres = Chef::EncryptedDataBagItem.load("postgresql", 'postgres', default_secret)
    node.normal['postgresql']['password']['postgres'] = postgres["password"]

    include_recipe "postgresql::server"

    package "php-postgresql" if FileTest.exist?("/usr/bin/php")

    include_recipe "postgresql::config_initdb"
    include_recipe "postgresql::config_pgtune"

    include_recipe "postgresql::ruby"

    template "/root/.pgpass" do
      source "pgpass.erb"
      variables(
        :password => postgres["password"]
      )
      group  "root"
      user   "root"
      mode   00600
      action :delete
    end

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
        path d["app_path"]
        owner d["app_user"]
        group d["app_user"]
        action :create
      end

      if d["app_backup"]
        rails_backup "pg_db_#{d["app_name"]}" do
          path        d["app_backup_path"]
          exec_pre    [
            "mkdir -p #{d["app_backup_dir"]} >> /dev/null 2>&1",
            "rm -rf #{d["app_backup_dir"]}/*",
            "su postgres -c 'pg_dump -U postgres #{d["name"]} | bzip2 > /tmp/#{d["name"]}.#{date}.sql.bz2'",
            "mv /tmp/#{d["name"]}.#{date}.sql.bz2 #{d["app_backup_dir"]}/#{d["name"]}.#{date}.sql.bz2",
            "chown #{d["app_user"]}:#{d["app_user"]} #{d["app_backup_dir"]}/#{d["name"]}.#{date}.sql.bz2"
          ]
          include     [d["app_backup_dir"]]
          archive_dir d["app_backup_archive"]
          temp_dir    d["app_backup_temp"]
        end
      else
        rails_backup "pg_db_#{d["app_name"]} delete" do
          action :delete
        end
        directory d["app_backup_archive"] do
          action :delete
        end
        directory d["app_backup_temp"] do
          action :delete
        end
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
      end
    end
  else
    postgresql_init = File.join("/etc/init.d", node['postgresql']['server']['service_name'])
    if FileTest.file? postgresql_init
      service node['postgresql']['server']['service_name'] do
        action [:stop, :disable]
      end
    end
  end

  # Backup MySQL User DB

  if node.default["rails"]["databases"].include? "mysql"
    root = Chef::EncryptedDataBagItem.load("mysql", 'root', default_secret)
    if root
      node.normal['mysql']['server_debian_password'] = root["debian_password"]
      node.normal['mysql']['server_root_password']   = root["password"]
      node.normal['mysql']['server_repl_password']   = root["replication_password"]
    end

    include_recipe "mysql::client"

    if node['rails'].include? "mysql"
      template '/etc/mysql/conf.d/tune.cnf' do
        owner 'mysql'
        owner 'mysql'
        source 'mysql_tune.cnf.erb'
        variables(
          :config => node['rails']['mysql']
        )
        notifies :restart, "mysql_service[#{node['mysql']['service_name']}]"
      end
    end

    include_recipe "mysql::server"

    include_recipe "database::mysql"

    package "php-mysql" if FileTest.exist?("/usr/bin/php")

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
        path d["app_path"]
        owner d["app_user"]
        group d["app_user"]
        action :create
      end

      if d["app_backup"]
        rails_backup "mysql_db_#{d["app_name"]}" do
          path        d["app_backup_path"]
          exec_pre    [
            "mkdir -p #{d["app_backup_dir"]} >> /dev/null 2>&1",
            "rm -rf #{d["app_backup_dir"]}/*",
            "mysqldump -u root -p#{root["password"]} #{d["name"]} | bzip2 > #{d["app_backup_dir"]}/#{d["name"]}.#{date}.sql.bz2"
          ]
          include     [d["app_backup_dir"]]
          archive_dir d["app_backup_archive"]
          temp_dir    d["app_backup_temp"]
        end
      else
        rails_backup "mysql_db_#{d["app_name"]} delete" do
          action :delete
        end
        directory d["app_backup_archive"] do
          action :delete
        end
        directory d["app_backup_temp"] do
          action :delete
        end
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
  else
    mysql_init = File.join("/etc/init.d", "mysqld")
    if FileTest.file? mysql_init
      service "mysqld" do
        action [:stop, :disable]
      end
    end
  end

  # Backup All Databases

  db_backup_root = "/var/tmp/db_backup"

  node['rails']['duplicity']['db'].each do |db|
    pre = [
      "mkdir -p #{db_backup_root}/#{db} >> /dev/null 2>&1",
      "rm -rf #{db_backup_root}/#{db}/*",
    ]
    db_backup_dir = "#{db_backup_root}/#{db}"
    case db
      when "postgresql"
        postgres = postgres || Chef::EncryptedDataBagItem.load("postgresql", 'postgres', default_secret)
        pre.push "su postgres -c 'pg_dump_all -U postgres | bzip2 > /tmp/#{db}.#{date}.sql.bz2'"
        pre.push "mv /tmp/#{db}.#{date}.sql.bz2 #{db_backup_dir}/#{db}.#{date}.sql.bz2"
        pre.push "chown root:root #{db_backup_dir}/#{db}.#{date}.sql.bz2"
      when "mysql"
        root = root || Chef::EncryptedDataBagItem.load("mysql", 'root', default_secret)
        pre.push "mysqldump --all-databases -u root -p#{root["password"]} | bzip2 > #{db_backup_dir}/#{db}.#{date}.sql.bz2"
      when "mongodb"
        admin = admin || Chef::EncryptedDataBagItem.load("mongodb", "admin", default_secret)
        pre.push "mongodump --dbpath #{node['mongodb']['config']['dbpath']} --out #{db_backup_dir}/#{db}.#{date}"
        pre.push "bzip2 -c #{db_backup_dir}/#{db}.#{date} > #{db_backup_dir}/#{db}.#{date}.bz2"
        pre.push "rm -f #{db_backup_dir}/#{db}.#{date}"
    end

    rails_backup "#{db}_db_backup" do
      path        "db/#{db}"
      exec_pre    pre
      include     [db_backup_dir]
      archive_dir "/tmp/da-#{db}"
      temp_dir    "/tmp/dt-#{db}"
    end
  end

  if Dir.exist? db_backup_root
    Dir.foreach(db_backup_root) do |db|
      next if db == '.' or db == '..'
      unless node['rails']['duplicity']['db'].include? db
        rails_backup "#{db}_db_delete" do
          action :delete
        end
        directory "/tmp/da-#{db}" do
          action :delete
        end
        directory "/tmp/dt-#{db}" do
          action :delete
        end
        directory "#{db_backup_root}/#{db}" do
          action :delete
        end
      end
    end
  end
end
