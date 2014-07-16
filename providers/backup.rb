#
# Cookbook Name:: rails
# Provider:: backup
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

action :create do
  unless node.role? 'vagrant'
    if Chef.const_defined?('EncryptedDataBagItem')
      case node['rails']['duplicity']['method']
      when 'aws'
        store_keys = data_bag('aws')
      when 'gs'
        store_keys = data_bag('gs')
      end
      duplicity = data_bag('duplicity')
      pass_key_id = new_resource.pass_key_id || node['rails']['duplicity']['pass_key_id']
      storage_key_id = new_resource.storage_key_id || node['rails']['duplicity']['storage_key_id']
      if duplicity.include?(pass_key_id) && store_keys.include?(storage_key_id)
        config storage_key_id, pass_key_id
      end
    end
  end
end

action :delete do
  duplicity_ng_cronjob "backup #{new_resource.name}" do
    action :delete
  end
  if (new_resource.boto_cfg || node['rails']['duplicity']['boto_cfg']) && new_resource.main
    duplicity_ng_boto 'delete boto config' do
      action :delete
    end
  end
end

def config(storage_key_id, pass_key_id)
  return unless storage_key_id || pass_key_id

  default_secret = Chef::EncryptedDataBagItem.load_secret("#{node['rails']['secrets']['default']}")

  case node['rails']['duplicity']['method']
  when 'aws'
    store = Chef::EncryptedDataBagItem.load('aws', storage_key_id, default_secret)
  when 'gs'
    store = Chef::EncryptedDataBagItem.load('gs', storage_key_id, default_secret)
  end

  use_config(new_resource, pass_key_id, store) if store['access_key_id'] && store['secret_access_key']
end

def use_config(new_resource, pass_key_id, store)
  return unless store

  boto = new_resource.boto_cfg || node['rails']['duplicity']['boto_cfg']
  boto_config(store) if boto && new_resource.main

  duplicity = Chef::EncryptedDataBagItem.load('duplicity', pass_key_id, default_secret)
  cronjob_script new_resource, boto, duplicity if duplicity['passphrase']
end

def cronjob_script(new_resource, boto)
  aws_eu = (new_resource.s3_eu || node['rails']['duplicity']['s3']['eu']) ? '--s3-use-new-style --s3-european-buckets ' : ''
  logfile = (new_resource.log || node['rails']['duplicity']['log']) ? (new_resource.logfile || node['rails']['duplicity']['log_file']) : '/dev/null'
  duplicity_ng_cronjob "backup #{new_resource.name}" do
    name new_resource.name # Cronjob filename (name_attribute)

    # Attributes for the default cronjob template
    interval         new_resource.interval || node['rails']['duplicity']['interval'] # Cron interval (hourly, daily, monthly)
    logfile          logfile          # Log cronjob output to this file

    # duplicity parameters
    # Backend to use (default: nil, required!)
    backend    "#{aws_eu}#{node['rails']['duplicity']['method']}://#{new_resource.target || node['rails']['duplicity']['target']}/#{node['fqdn']}/#{new_resource.path || node['rails']['duplicity']['path']}"
    passphrase duplicity_main['passphrase']                 # duplicity passphrase (default: nil, required!)

    include                   new_resource.include || node['rails']['duplicity']['include']  # Default directories to backup
    exclude                   new_resource.exclude || node['rails']['duplicity']['exclude']                      # Default directories to exclude from backup
    archive_dir               new_resource.archive_dir || node['rails']['duplicity']['archive_dir']   # duplicity archive directory
    temp_dir                  new_resource.temp_dir || node['rails']['duplicity']['temp_dir']       # duplicity temp directory
    keep_full                 new_resource.keep_full || node['rails']['duplicity']['keep_full']                         # Keep 5 full backups
    nice                      node['rails']['duplicity']['nice']                         # Be nice (cpu)
    ionice                    node['rails']['duplicity']['ionice']                          # Ionice class (3 => idle)
    full_backup_if_older_than new_resource.full_per || node['rails']['duplicity']['full_per']           # Take a full backup after this interval

    exec_pre                  new_resource.exec_pre || node['rails']['duplicity']['exec_pre']
    exec_before               new_resource.exec_before || node['rails']['duplicity']['exec_before']
    exec_after                new_resource.exec_after || node['rails']['duplicity']['exec_after']

    #
    # # In case you use Swift as you backend, specify the credentials here
    # swift_username 'mySwiftUsername'
    # swift_password 'mySwiftPassword'
    # swift_authurl  'SwiftAuthURL'

    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id'] if node['rails']['duplicity']['method'].include?('gs') && !boto
    gs_secret_access_key store['secret_access_key'] if node['rails']['duplicity']['method'].include?('gs') && !boto

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id'] if node['rails']['duplicity']['method'].include?('aws') && !boto_cfg
    aws_secret_access_key store['secret_access_key'] if node['rails']['duplicity']['method'].include?('aws') && !boto
  end
end

def boto_config(store)
  return unless store
  duplicity_ng_boto 'base boto config' do
    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id'] if node['rails']['duplicity']['method'].include?('gs')
    gs_secret_access_key store['secret_access_key'] if node['rails']['duplicity']['method'].include?('gs')

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id'] if node['rails']['duplicity']['method'].include?('aws')
    aws_secret_access_key store['secret_access_key'] if node['rails']['duplicity']['method'].include?('aws')
  end
end
