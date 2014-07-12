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

rails_backup "system"

# unless node.role? "vagrant"
#   if Chef.const_defined?("EncryptedDataBagItem")
#     default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")
#     case node['rails']['duplicity']['method']
#     when "aws"
#       store_keys = data_bag("aws")
#     when "gs"
#       store_keys = data_bag("gs")
#     end
#     duplicity = data_bag("duplicity")
#     if duplicity.include?("main") and store_keys.include?("main")
#       duplicity_main = Chef::EncryptedDataBagItem.load("duplicity", "main", default_secret)
#       case node['rails']['duplicity']['method']
#       when "aws"
#         store_main = Chef::EncryptedDataBagItem.load("aws", "main", default_secret)
#       when "gs"
#         store_main = Chef::EncryptedDataBagItem.load("gs", "main", default_secret)
#       end
#       if duplicity_main["passphrase"] and store_main["access_key_id"] and store_main["secret_access_key"]
#         backup_paths = node['rails']['duplicity']['include']
#         aws_eu = node['rails']['duplicity']['s3']['eu'] ? "--s3-use-new-style --s3-european-buckets " : ""
#         logfile = node['rails']['duplicity']['log'] ? node['rails']['duplicity']['log_file'] : '/dev/null'
#         duplicity_ng_cronjob 'backup' do
#           name 'backup' # Cronjob filename (name_attribute)
#
#           # Attributes for the default cronjob template
#           interval         node['rails']['duplicity']['interval']              # Cron interval (hourly, daily, monthly)
#           logfile          logfile          # Log cronjob output to this file
#
#           duplicity_path   node['rails']['duplicity']['path']
#
#           # duplicity parameters
#           backend    "#{aws_eu}#{node['rails']['duplicity']['method']}://#{node['rails']['duplicity']['target']}/#{node['fqdn']}" # Backend to use (default: nil, required!)
#           passphrase duplicity_main["passphrase"]                 # duplicity passphrase (default: nil, required!)
#
#           include        backup_paths # Default directories to backup
#           exclude        node['rails']['duplicity']['exclude']                       # Default directories to exclude from backup
#           archive_dir    node['rails']['duplicity']['archive_dir']   # duplicity archive directory
#           temp_dir       node['rails']['duplicity']['temp_dir']       # duplicity temp directory
#           keep_full      node['rails']['duplicity']['keep_full']                          # Keep 5 full backups
#           nice           node['rails']['duplicity']['nice']                         # Be nice (cpu)
#           ionice         node['rails']['duplicity']['ionice']                          # Ionice class (3 => idle)
#           full_backup_if_older_than node['rails']['duplicity']['full_per']            # Take a full backup after this interval
#
#           # # Command(s) to run at the very beginning of the cronjob (default: empty)
#           # exec_pre %(if [ -f "/nobackup" ]; then exit 0; fi)
#           #
#           # # Command(s) to run after cleanup, but before the backup (default: empty)
#           # exec_before ['pg_dumpall -U postgres |bzip2 > /tmp/dump.sql.bz2']
#           #
#           # # Command(s) to run after the backup has finished (default: empty)
#           # exec_after  ['touch /backup-sucessfull', 'echo yeeeh']
#           #
#           # # In case you use Swift as you backend, specify the credentials here
#           # swift_username 'mySwiftUsername'
#           # swift_password 'mySwiftPassword'
#           # swift_authurl  'SwiftAuthURL'
#
#           # In case you use S3 as your backend, your credentials go here
#           gs_access_key_id     store_main["access_key_id"] if node['rails']['duplicity']['method'].include?("gs")
#           gs_secret_access_key store_main["secret_access_key"] if node['rails']['duplicity']['method'].include?("gs")
#
#           # In case you use S3 as your backend, your credentials go here
#           aws_access_key_id     store_main["access_key_id"] if node['rails']['duplicity']['method'].include?("aws")
#           aws_secret_access_key store__main["secret_access_key"] if node['rails']['duplicity']['method'].include?("aws")
#         end
#       end
#     end
#   end
# end

include_recipe "msmtp"
include_recipe "rails::cleanup"
