#
# Cookbook Name:: rails
# Provider:: users
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
  users  = new_resource.users
  secret = new_resource.secret
  vcs    = new_resource.vcs

  if users && secret && vcs
    users_data = []

    user_nginx

    users.each do |u| # rubocop:disable Style/Next
      data = ::Chef::EncryptedDataBagItem.load('users', u, secret)
      next unless data

      ftp_list = user_ftps(u, data)
      users_data = users_data.push(ftp_list).flatten.compact unless ftp_list.empty?

      user u do
        home      "/home/#{u}"
        password  data['password']
        shell     data['shell']
        comment   data['comment']
        supports  manage_home: true
      end

      group "#{node['nginx']['user']} #{u}" do
        group_name node['nginx']['user']
        append     true
        members    [u]
      end

      user_groups(u)

      user_ssh_keys(u, data)

      user_vcs_keys(u, data, vcs, secret)
    end

    node.default['vsftpd']['config']['ftp_username'] = node['nginx']['user']
    node.default['vsftpd']['config']['chown_username'] = node['nginx']['user']
    node.default['vsftpd']['config']['guest_username'] = node['nginx']['user']

    vsftpd_virtual_users 'vsftpd_credentials' do
      users users_data
    end
  end

  new_resource.updated_by_last_action(true)
end

def user_ssh_keys(u, data) # rubocop:disable Style/MethodLength
  return unless data['ssh-keys'] && u

  directory "/home/#{u}/.ssh" do
    action :create
    owner  u
    group  u
    mode   00700
  end

  template "/home/#{u}/.ssh/authorized_keys" do
    source 'authorized_keys.erb'
    owner     u
    group     u
    mode      00600
    variables keys: data['ssh-keys']
  end
end

def user_vcs_keys(u, data, vcs, secret) # rubocop:disable Style/MethodLength
  return unless data['vcs'] && u && secret

  data['vcs'].each do |v|
    next unless vcs.include?(v)

    key = ::Chef::EncryptedDataBagItem.load('vcs_keys', v, secret)

    file "/home/#{u}/.ssh/#{key['file-name']}" do
      content key['file-content']
      owner   u
      group   u
      mode    00600
    end

    ssh_known_hosts_entry "#{key['host']} #{u}" do
      host key['host']
      file "/home/#{u}/.ssh/known_hosts"
      owner u
    end
  end

  template "/home/#{u}/.ssh/config" do
    source 'ssh_config.erb'
    owner  u
    group  u
    mode  '0600'
    variables vcs: data['vcs']
  end
  template "/home/#{u}/.gitconfig" do
    source 'gitconfig.erb'
    owner u
    group u
    mode 00644

    variables(
        name:  u,
        email: "#{u}@#{node['fqdn']}"
    )
  end
end

def user_groups(u) # rubocop:disable Style/MethodLength
  return unless u

  if u == node['rails']['user']['deploy']
    group 'admin' do
      append  true
      members [node['rails']['user']['deploy']]
    end
  else
    group u do
      append  true
      members [node['nginx']['user'], node['rails']['user']['deploy']]
    end
  end

  group "#{node['rbenv']['group']} #{u}" do
    group_name node['rbenv']['group']
    append     true
    members    [u]
    only_if { node.role? 'base_ruby' }
  end

  group "#{node['msmtp']['group']} #{u}" do
    group_name node['msmtp']['group']
    append     true
    members    [u]
  end
end

def user_ftps(u, data) # rubocop:disable Style/MethodLength
  return %w() unless data['ftp'] && u

  users = []
  data['ftp'].each do |ftp|
    local_root = ftp['local_root'] || "#{node['rails']['sites_base_path']}/#{u}"
    users.push(
      'name' => ftp['name'],
      'password' => ftp['password'],
      'config' => {
        'local_root' => local_root,
        'dirlist_enable' => 'YES',
        'download_enable' => 'YES',
        'write_enable' => 'YES',
        'chown_username' => u,
        'guest_username' => u,
        'ftp_username' => u,
      }
    )
  end
  users
end

def user_nginx
  return if node['nginx']['source']['use_existing_user']

  user node['nginx']['user'] do
    system true
    shell  '/bin/false'
    home   '/var/www'
  end
  node.default['nginx']['source']['use_existing_user'] = true
end
