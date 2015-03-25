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

require 'fileutils'

action :create do
  store_keys = nil

  if aws?
    store_keys = data_bag('aws')
  elsif gs?
    store_keys = data_bag('gs')
  elsif swift?
    store_keys = data_bag('swift')
  elsif azure?
    store_keys = data_bag('azure')
  end

  if store_keys
    duplicity = data_bag('duplicity')
    pass_key_id = new_resource.pass_key_id
    storage_key_id = new_resource.storage_key_id
    if duplicity.include?(pass_key_id) && store_keys.include?(storage_key_id)
      config new_resource, storage_key_id, pass_key_id
    end
  end

  collect_units new_resource.name

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

action :cleanup do
  backup_cleanup
  backup_tmp_cleanup

  new_resource.updated_by_last_action(true)
end

def backup_cleanup
  cron_root = "/etc/cron.#{new_resource.interval}"
  return unless ::Dir.exist?(cron_root)

  ::Dir.foreach(cron_root) do |cron|
    next if cron == '.' || cron == '..' || !cron.include?('duplicity')
    name = cron.sub('duplicity-', '')
    next if backup_active?(name)

    duplicity_ng_cronjob "cleanup backup #{name}" do
      name name
      action :delete
    end
  end
end

def config(new_resource, storage_key_id, pass_key_id) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  return unless storage_key_id || pass_key_id

  default_secret = ::Chef::EncryptedDataBagItem.load_secret(node['rails']['secrets']['default'])

  if aws?
    store = ::Chef::EncryptedDataBagItem.load('aws', storage_key_id, default_secret)
  elsif gs?
    store = ::Chef::EncryptedDataBagItem.load('gs', storage_key_id, default_secret)
  elsif swift?
    store = ::Chef::EncryptedDataBagItem.load('swift', storage_key_id, default_secret)
  elsif azure?
    store = ::Chef::EncryptedDataBagItem.load('azure', storage_key_id, default_secret)
  else
    return
  end

  use_config(new_resource, pass_key_id, store, default_secret)
end

def use_config(new_resource, pass_key_id, store, default_secret)
  return unless store

  boto = new_resource.boto_cfg
  boto_config(store) if boto && new_resource.main && !swift?

  duplicity = ::Chef::EncryptedDataBagItem.load('duplicity', pass_key_id, default_secret)
  cronjob_script new_resource, store, boto, duplicity if duplicity['passphrase']
end

def cronjob_script(new_resource, store, boto, duplicity_main) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
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
    swift_username       store['username'] if is_swift?
    swift_password       store['password'] if is_swift?
    swift_authurl        store['authurl']  if is_swift?

    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id']     if is_gs? && !boto
    gs_secret_access_key store['secret_access_key'] if is_gs? && !boto

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id']     if is_aws? && !boto
    aws_secret_access_key store['secret_access_key'] if is_aws? && !boto

    # In case you use Microsoft Azure
    azure_account_name store['account_name'] if is_azure?
    azure_account_key  store['account_key']  if is_azure?
  end
end

def backend_uri(method, target, path = '', aws_eu = '')
  if swift?
    "#{method}://#{node['fqdn']}_#{clean_path(path)}"
  elsif azure?
    "#{method}://#{clean_path(node['fqdn'], '-').gsub('.', '-')}-#{clean_path(path, '-').gsub('.', '-')}".gsub('--', '-').downcase
  else
    "#{aws_eu}#{method}://#{target}/#{node['fqdn']}/#{path}"
  end
end

def boto_config(store)
  return unless store
  duplicity_ng_boto 'base boto config' do
    # In case you use Google Cloud Storage as your backend, your credentials go here
    gs_access_key_id     store['access_key_id'] if is_gs?
    gs_secret_access_key store['secret_access_key'] if is_gs?

    # In case you use S3 as your backend, your credentials go here
    aws_access_key_id     store['access_key_id'] if is_aws?
    aws_secret_access_key store['secret_access_key'] if is_aws?
  end
end

# Helpers

def gs?
  node['rails']['duplicity']['method'].include?('gs')
end
alias_method :is_gs?, :gs?

def aws?
  node['rails']['duplicity']['method'].include?('s3')
end
alias_method :is_aws?, :aws?

def swift?
  node['rails']['duplicity']['method'].include?('swift')
end
alias_method :is_swift?, :swift?

def azure?
  node['rails']['duplicity']['method'].include?('azure')
end
alias_method :is_azure?, :azure?

def backup_active?(name)
  node['rails']['duplicity']['units'].each do |backup|
    return true if backup[:name] == name
  end
  false
end

def backup_tmp_active?(name)
  node['rails']['duplicity']['units'].each do |backup|
    return true if name.include?(backup[:name])
  end
  false
end

def backup_tmp_cleanup
  ::Dir[::File.join('/tmp/d{a,t}-*-*')].each do |d|
    next if backup_tmp_active?(d)

    ::FileUtils.remove_dir(d)
  end
end

def clean_path(path, replacement = '_')
  return unless path
  cleaned = path.gsub(/[_\-\?\+\/\\+]/, replacement)
  if cleaned.include? '_db'
    cleaned[/[a-z_\-\.]+\/[a-z]+$/].sub('/', replacement)
  else
    cleaned[/[a-z0-9_\-\.]+$/]
  end.sub(/^#{replacement}/, '')
end

def collect_units(name)
  node.default['rails']['duplicity']['units'] << { name: name }
end
