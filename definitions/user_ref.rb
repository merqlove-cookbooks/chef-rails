#
# Cookbook Name:: rails
# Definition:: user_ref
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

define :user_ref, users: false, secret: false, vcs: false do
  if params[:users] and params[:secret] and params[:vcs]
    users = params[:users]
    default_secret =  params[:secret]
    vcs = params[:vcs]
    name_pass = []

    users.each do |u|
      data = Chef::EncryptedDataBagItem.load('users', u, default_secret)
      if data
        if data["ftp"]
          data["ftp"].each do |ftp|
            name_pass.push({'name' => ftp["name"], 'password' => ftp["password"] })
            node.default['vsftpd']['users'].push({
              'name' => ftp["name"], 
              'config' => {
                'local_root' => "#{node['rails']['sites_base_path']}/#{u}",
                'dirlist_enable' => 'YES',
                'download_enable' => 'YES',
                'write_enable' => 'YES',
                'chown_username' => u,
                'guest_username' => u,
                'ftp_username' => u,
              }
            })

            node.default['vsftpd']['allowed'].push(ftp["name"])
          end

          group "#{node['nginx']['user']} #{u}" do
            group_name node['nginx']['user']
            append true
            members [u]
          end 
        end

        user u do
          home      "/home/#{u}"
          password  data["password"]
          shell     data["shell"]
          comment   data["comment"]
          supports  :manage_home => true
        end

        if u == node['rails']['user']['deploy']
          group "admin" do
            append true
            members [node['rails']['user']['deploy']]
          end
        else
          group a["user"] do
            append true
            members [node['nginx']['user'], node['rails']['user']['deploy']]
          end
        end

        if node.role? "base_ruby"
          group "#{node[:rbenv][:group]} #{u}" do
            group_name node[:rbenv][:group]
            append true
            members [u]
          end
        end

        group "#{node[:msmtp][:group]} #{u}" do
          group_name node[:msmtp][:group]
          append true
          members [u]
        end

        if data["ssh-keys"]
          directory "/home/#{u}/.ssh" do
            action :create
            owner  u
            group  u
            mode   '0700'
          end

          template "/home/#{u}/.ssh/authorized_keys" do
            source 'authorized_keys.erb'
            owner  u
            group  u
            mode  '0600'
            variables :keys => data["ssh-keys"]
          end
        end

        if data["vcs"]
          data["vcs"].each do |v|
            if vcs.include? v
              key = Chef::EncryptedDataBagItem.load("vcs_keys", v, default_secret)

              file "/home/#{u}/.ssh/#{key["file-name"]}" do
                content key['file-content']
                owner u
                group u
                mode 0600
              end

              ssh_known_hosts_entry "#{key["host"]} #{u}" do
                host key["host"]
                file "/home/#{u}/.ssh/known_hosts"
                owner u
              end
            end
          end

          template "/home/#{u}/.ssh/config" do
            source 'ssh_config.erb'
            owner  u
            group  u
            mode  '0600'
            variables :vcs => data["vcs"]
          end
          template "/home/#{u}/.gitconfig" do
            source 'gitconfig.erb'
            owner u
            group u
            mode '0644'

            variables(
              :name  => u,
              :email => "#{u}@#{node['fqdn']}"
            )
          end
        end
      end
    end

    node.default['vsftpd']['config']['ftp_username'] = node['nginx']['user']
    node.default['vsftpd']['config']['chown_username'] = node['nginx']['user']
    node.default['vsftpd']['config']['guest_username'] = node['nginx']['user']

    vsftpd_virtual_users "vsftpd_credentials" do
      users name_pass
    end

  end
end
