#
# Cookbook Name:: rails
# Definition:: databases
#
# Copyright (C) 2013 Alexander Merkulov
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

default_secret = ::Chef::EncryptedDataBagItem.load_secret(node['rails']['secrets']['default'])
date = 'NOW=$(date +"%Y%m%d")'

rails_db 'initialize' do
  secret default_secret
  date   date
end

# Backup All Databases

db_backup_root = '/var/tmp/db_backup'

node['rails']['duplicity']['db'].each do |db|

  db_backup_dir = "#{db_backup_root}/#{db}"

  exec_pre = [
    "mkdir -p #{db_backup_dir} >> /dev/null 2>&1",
  ]

  exec_before = [
    date,
    "rm -rf #{db_backup_dir}/*",
  ]

  case db
  when 'postgresql'
    exec_before.push "su postgres -c 'pg_dumpall -U postgres | gzip > /tmp/#{db}.\"$0\".sql.gz' -- \"$NOW\""
    exec_before.push "mv /tmp/#{db}.$NOW.sql.gz #{db_backup_dir}/"
    exec_before.push "chown -R root:root #{db_backup_dir}/*"
  when 'mysql'
    root ||= ::Chef::EncryptedDataBagItem.load(db, 'root', default_secret)
    exec_before.push "mysqldump --all-databases -u root -p#{root['password']} | gzip > #{db_backup_dir}/#{db}.$NOW.sql.gz"
  when 'mongodb'
    exec_before.push "mongodump --dbpath #{node['mongodb']['config']['dbpath']} --out #{db_backup_dir}/#{db}.$NOW >> /dev/null 2>&1"
    exec_before.push "ar -zcf #{db_backup_dir}/#{db}.$NOW.tar.gz #{db_backup_dir}/#{db}.$NOW >> /dev/null 2>&1"
    exec_before.push "rm -rf #{db_backup_dir}/#{db}.$NOW"
  end

  rails_backup "#{db}_db_backup" do
    path        "db/#{db}"
    exec_pre    exec_pre
    exec_before exec_before
    include     [db_backup_dir]
    archive_dir "/tmp/da-#{db}"
    temp_dir    "/tmp/dt-#{db}"
  end
end

if ::Dir.exist? db_backup_root
  ::Dir.foreach(db_backup_root) do |db|
    next if db == '.' || db == '..'

    ruby_block "#{db}_db_delete" do
      block do
        ::FileUtils.remove_dir("/tmp/da-#{db}") if ::Dir.exist?("/tmp/da-#{db}")
        ::FileUtils.remove_dir("/tmp/dt-#{db}") if ::Dir.exist?("/tmp/dt-#{db}")
        ::FileUtils.remove_dir("#{db_backup_root}/#{db}") if ::Dir.exist?("#{db_backup_root}/#{db}")
      end
      action :nothing
    end

    rails_backup "delete #{db}_db_backup" do
      name "#{db}_db_backup"
      action :delete
      not_if { node['rails']['duplicity']['db'].include? db }
      notifies :create, "ruby_block[#{db}_db_delete]"
    end
  end
end
