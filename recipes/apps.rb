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
node.default["rails"]["databases"] = {}

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
  include_recipe "php-fpm::configure"
  template "/etc/php.d/php_fix.ini" do
    owner "root"
    group "root"
    mode '755'
    source 'php_fix.erb'
    notifies :restart, 'service[php-fpm]', :delayed
  end

  ruby_block "cleanup php-fpm configuration" do
    block do
      if Dir.exist? "#{node['php-fpm']['pool_conf_dir']}"
        deleted = false
        Dir.foreach("#{node['php-fpm']['pool_conf_dir']}") do |pool|
          next if pool == '.' or pool == '..'
          if pool.include? ".conf"
            unless Rails::Helpers.has_hash_in_array?(node['php-fpm']['pools'], pool.gsub(/\.conf/, ''))
              File.delete("#{node['php-fpm']['pool_conf_dir']}/#{pool}")
              deleted = true
            end
          end
        end

        resources(:service => node['php-fpm']['service']).run_action(:restart) if deleted
      end
    end
    action :create
  end

  directory "/var/lib/php/session" do
    owner "root"
    group "root"
    mode "0777"
  end

  include_recipe "php-fpm::install"
else
  if Dir.exist? "#{node['php-fpm']['pool_conf_dir']}"
    Dir.foreach("#{node['php-fpm']['pool_conf_dir']}") do |pool|
      next if pool == '.' or pool == '..'
      if pool.include? ".conf"
        File.delete("#{node['php-fpm']['pool_conf_dir']}/#{pool}")
      end
    end
    service node['php-fpm']['service'] do
      action [:disable, :stop]
    end
  end
end

#Sites cleanup
if node['rails']['sites'].count > 0
  execute "deny site groups from write" do
    command "chmod -R g-w #{node['rails']['sites_base_path']}/*/*/docs"
    action :run
  end

  execute "deny site others from read" do
    command "chmod -R o-rwx #{node['rails']['sites_base_path']}/*/*/docs"
    action :run
  end
end

include_recipe "rails::databases"
include_recipe "rails::database_admin"

unless node.role? "vagrant"
  prefix = "backups_"
  node['tags'].each do |tag|
    prefix += tag[/server\_/,''] if tag.include? "server_"
  end
  if Chef.const_defined?("EncryptedDataBagItem")
    default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
    aws = data_bag("aws")
    duplicity = data_bag("duplicity")
    if duplicity.include?("passphrase")
      passphrase = Chef::EncryptedDataBagItem.load("duplicity", "passphrase", default_secret)
      if aws.include?("aws_access_key_id") and aws.include?("aws_secret_access_key")
        aws_access_key_id = Chef::EncryptedDataBagItem.load("aws", "aws_access_key_id", default_secret)
        aws_secret_access_key = Chef::EncryptedDataBagItem.load("aws", "aws_secret_access_key", default_secret)
        aws_host = aws.include?("aws_host") ? Chef::EncryptedDataBagItem.load("aws", "aws_host", default_secret) : "s3.amazonaws.com"
        aws_eu = Chef::EncryptedDataBagItem.load("aws", "aws_eu", default_secret) if aws.include?("aws_eu")
        duplicity_ng_cronjob 'dbackup' do
          name 'dbackup' # Cronjob filename (name_attribute)

          # Attributes for the default cronjob template
          interval         'daily'              # Cron interval (hourly, daily, monthly)
          duplicity_path   '/usr/bin/duplicity' # Path to duplicity
          configure_zabbix false                # Automatically configure zabbix user paremeters
          logfile          '/dev/null'          # Log cronjob output to this file

          # duplicity parameters
          backend    "s3://#{aws_host}/#{prefix}/#{node['fqdn']}" # Backend to use (default: nil, required!)
          passphrase passphrase                 # duplicity passphrase (default: nil, required!)

          include        %w(/etc/ /root/ /var/log/) # Default directories to backup
          exclude        %w()                       # Default directories to exclude from backup
          archive_dir    '/tmp/duplicity-archive'   # duplicity archive directory
          temp_dir       '/tmp/duplicity-tmp'       # duplicity temp directory
          keep_full      1                          # Keep 5 full backups
          nice           10                         # Be nice (cpu)
          ionice         3                          # Ionice class (3 => idle)
          full_backup_if_older_than '7D'            # Take a full backup after this interval

          # # Command(s) to run at the very beginning of the cronjob (default: empty)
          # exec_pre %(if [ -f "/nobackup" ]; then exit 0; fi)
          #
          # # Command(s) to run after cleanup, but before the backup (default: empty)
          # exec_before ['pg_dumpall -U postgres |bzip2 > /tmp/dump.sql.bz2']
          #
          # # Command(s) to run after the backup has finished (default: empty)
          # exec_after  ['touch /backup-sucessfull', 'echo yeeeh']
          #
          # # In case you use Swift as you backend, specify the credentials here
          # swift_username 'mySwiftUsername'
          # swift_password 'mySwiftPassword'
          # swift_authurl  'SwiftAuthURL'

          # In case you use S3 as your backend, your credentials go here
          aws_access_key_id     aws_access_key_id
          aws_secret_access_key aws_secret_access_key
          aws_eu (aws_eu ? aws_eu : true)
        end
      end
    end
  end
end

include_recipe "msmtp"
include_recipe "rails::cleanup"
