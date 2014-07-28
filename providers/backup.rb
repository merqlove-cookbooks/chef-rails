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
  store_keys = nil

  if aws?
    store_keys = data_bag('aws')
  elsif gs?
    store_keys = data_bag('gs')
  elsif swift?
    store_keys = data_bag('swift')
  end

  if store_keys
    duplicity = data_bag('duplicity')
    pass_key_id = new_resource.pass_key_id
    storage_key_id = new_resource.storage_key_id
    if duplicity.include?(pass_key_id) && store_keys.include?(storage_key_id)
      config new_resource, storage_key_id, pass_key_id
    end
  end

  new_resource.updated_by_last_action(true)
end

action :delete do
  duplicity_ng_cronjob "delete backup #{new_resource.name}" do
    name new_resource.name
    action :delete
  end

  duplicity_ng_boto "delete boto config #{new_resource.name}" do
    action :delete
    only_if { new_resource.boto_cfg && new_resource.main }
  end

  new_resource.updated_by_last_action(true)
end

def config(new_resource, storage_key_id, pass_key_id) # rubocop:disable Style/CyclomaticComplexity,Style/MethodLength
  return unless storage_key_id || pass_key_id

  default_secret = Chef::EncryptedDataBagItem.load_secret(node['rails']['secrets']['default'])

  if aws?
    store = Chef::EncryptedDataBagItem.load('aws', storage_key_id, default_secret)
  elsif gs?
    store = Chef::EncryptedDataBagItem.load('gs', storage_key_id, default_secret)
  elsif swift?
    store = Chef::EncryptedDataBagItem.load('swift', storage_key_id, default_secret)
  else
    return
  end

  use_config(new_resource, pass_key_id, store, default_secret)
end

def use_config(new_resource, pass_key_id, store, default_secret)
  return unless store

  boto = new_resource.boto_cfg
  boto_config(store) if boto && new_resource.main && !swift?

  duplicity = Chef::EncryptedDataBagItem.load('duplicity', pass_key_id, default_secret)
  cronjob_script new_resource, store, boto, duplicity if duplicity['passphrase']
end

def cronjob_script(new_resource, store, boto, duplicity_main) # rubocop:disable Style/CyclomaticComplexity,Style/MethodLength
  aws_eu  = (new_resource.s3_eu) ? '--s3-use-new-style --s3-european-buckets ' : ''
  logfile = (new_resource.log) ? (new_resource.logfile) : '/dev/null'
  method  = node['rails']['duplicity']['method']
  target  = new_resource.target
  path    = new_resource.path
  duplicity_ng_cronjob "backup #{new_resource.name}" do
    name new_resource.name # Cronjob filename (name_attribute)

    # Attributes for the default cronjob template
    interval         new_resource.interval # Cron interval (hourly, daily, monthly)
    logfile          logfile # Log cronjob output to this file

    # duplicity parameters
    # Backend to use (default: nil, required!)
    backend    backend_uri(method, target, path, aws_eu)
    passphrase duplicity_main['passphrase']  # duplicity passphrase (default: nil, required!)

    include                   new_resource.include # Default directories to backup
    exclude                   new_resource.exclude # Default directories to exclude from backup
    archive_dir               new_resource.archive_dir # duplicity archive directory
    temp_dir                  new_resource.temp_dir # duplicity temp directory
    keep_full                 new_resource.keep_full # Keep 5 full backups
    nice                      node['rails']['duplicity']['nice'] # Be nice (cpu)
    ionice                    node['rails']['duplicity']['ionice'] # Ionice class (3 => idle)
    full_backup_if_older_than new_resource.full_per # Take a full backup after this interval

    exec_pre                  new_resource.exec_pre
    exec_before               new_resource.exec_before
    exec_after                new_resource.exec_after

    #
    # # In case you use Swift as you backend, specify the credentials here
    swift_username       store['username'] if swift?
    swift_password       store['password'] if swift?
    swift_authurl        store['authurl'] if swift?

    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id'] if gs? && !boto
    gs_secret_access_key store['secret_access_key'] if gs? && !boto

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id'] if aws? && !boto
    aws_secret_access_key store['secret_access_key'] if aws? && !boto
  end
end

def backend_uri(method, target, path = '', aws_eu = '')
  if swift?
    "#{method}://#{node['fqdn']}_#{clean_path(path)}"
  else
    "#{aws_eu}#{method}://#{target}/#{node['fqdn']}/#{path}"
  end
end

def boto_config(store)
  return unless store
  duplicity_ng_boto 'base boto config' do
    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id'] if gs?
    gs_secret_access_key store['secret_access_key'] if gs?

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id'] if aws?
    aws_secret_access_key store['secret_access_key'] if aws?
  end
end

def gs?
  node['rails']['duplicity']['method'].include?('gs')
end

def aws?
  node['rails']['duplicity']['method'].include?('s3')
end

def swift?
  node['rails']['duplicity']['method'].include?('swift')
end

def clean_path(path)
  return unless path
  out = path[/[a-z0-9_\-\.]+$/].sub(/^\_/,'')
  out << '_db' if path.include? 'db'
  out
end
