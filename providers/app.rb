#
# Cookbook Name:: rails
# Provider:: app
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
  if new_resource.application
    a            = new_resource.application
    type         = new_resource.type
    base_path    = node['rails']["#{type}_base_path"]
    project_path = if type.include? 'sites'
      "#{a['user']}/#{a['name']}"
    else
      a['name']
    end
    backup_db_path = if type.include? 'sites'
      "#{a['user']}/#{a['name']}_db"
    else
      "#{a['name']}_db"
    end
    app_path = "#{base_path}/#{project_path}"

    directory "#{base_path} #{a['name']} #{a['user']}" do
      path  "#{base_path}/#{a['user']}"
      owner a['user']
      group a['user']
      mode  00750
    end

    if a['backup']
      rails_backup a['name'] do
        path        "#{type}/#{project_path}"
        include     [app_path]
        exclude     ["#{app_path}/backup"]
        archive_dir "/tmp/da-#{a['user']}-#{a['name']}"
        temp_dir    "/tmp/dt-#{a['user']}-#{a['name']}"
      end
    else
      archive_dir = "/tmp/da-#{a['user']}-#{a['name']}"
      temp_dir    = "/tmp/dt-#{a['user']}-#{a['name']}"
      rails_backup a['name'] do
        action :delete
      end
      Dir.delete(archive_dir) if Dir.exist? archive_dir
      Dir.delete(temp_dir) if Dir.exist? temp_dir
    end

    directory app_path do
      owner     a['user']
      group     a['user']
      mode      00750
      recursive true
    end

    if a.include? 'db'
      a['db'].each do |d|
        node.default['rails']['databases'][d['type']][d['name']] = {
          name:               d['name'],
          user:               d['user'],
          password:           d['password'],
          pool:               d['pool'],
          app_type:           type,
          app_name:           a['name'],
          app_path:           app_path,
          app_user:           a['user'],
          app_delete:         a[:delete],
          app_backup:         a['backup'],
          app_backup_path:    "#{type}/#{backup_db_path}/#{d['type']}",
          app_backup_dir:     "#{app_path}/backup/#{d['type']}",
          app_backup_archive: "/tmp/da-#{a['user']}-#{d['type']}-#{d['name']}",
          app_backup_temp:    "/tmp/dt-#{a['user']}-#{d['type']}-#{d['name']}"
        }
      end
    end

    if a[:delete] && a[:name] && !a['name'].empty?
      if type.include?('sites') && a.include?('nginx')
        rails_nginx_vhost a['name'] do
          action :delete
        end
      end

      directory app_path do
        action :delete
      end

      next
    end

    if type.include?('sites') && a.include?('nginx')
      unless a[:enable]
        rails_nginx_vhost a['name'] do
          action :disable
        end
        next
      end
    end

    if node.default['rails']['ruby']
      if a.include?('rbenv')
        # set ruby
        begin
          rbenv_ruby "#{a['rbenv']['version']}" do
            ruby_version "#{a['rbenv']['version']}"
          end

          # add gems
          a['rbenv']['gems'].each do |g|
            rbenv_gem "#{g[:name]}" do
              ruby_version "#{a['rbenv']['version']}"
              version      g[:version] if g[:version]
            end
          end
        rescue Exception => e
          log 'message' do
            message "Upload Rbenv Cookbook.\n#{e.message}"
            level   :error
          end
        end
      end
    end

    if a.include? 'smtp'
      begin
        node.default['msmtp']['accounts'][a['user']][a['name']]          = a[:smtp]
        node.default['msmtp']['accounts'][a['user']][a['name']][:syslog] = 'on'
        node.default['msmtp']['accounts'][a['user']][a['name']][:syslog] = 'off'
        node.default['msmtp']['accounts'][a['user']][a['name']][:log]    = "#{app_path}/log/msmtp.log"
      rescue Exception => e
        log 'message' do
          message "Upload MSMTP Cookbook.\n#{e.message}"
          level :error
        end
      end
    end

    if a.include? 'php'
      begin
        if node['platform_version'].to_f < 6
          node.default['php']['packages'] = %w( php php-devel php-cli php-pear )
        end

        if File.exist?('/usr/bin/php')
          include_recipe 'composer::self_update'
        else
          include_recipe 'php'
          package 'php-gd'
          package 'php-pecl-memcached'
          package 'php-pecl-apcu'
          package 'php-mbstring' do
            action   :install
            notifies :reload, 'service[php-fpm]', :delayed
          end
          include_recipe 'composer'
        end

        directory "/var/lib/php/session/#{a['user']}_#{a['name']}" do
          owner     a['user']
          group     a['user']
          mode      00700
          action    :create
          recursive true
        end

        pool = node.default['php-fpm']['default']['pool'].dup

        pool_custom = {
          name: a['name'],
          listen: "/var/run/php-#{a['user']}-#{a['name']}.sock",
          user: a['user'],
          group: a['user'],
          php_options: {
            'php_value[session.save_path]' => "/var/lib/php/session/#{a['user']}_#{a['name']}",
            'php_admin_value[error_log]' => "#{app_path}/log/php-fpm-error_log.log",
            'slowlog' => "#{app_path}/log/php-fpm-slowlog.log",
            'php_admin_value[post_max_size]' => '16M',
            'php_admin_value[upload_max_filesize]' => '16M',
            'request_slowlog_timeout' => '5s',
            # 'php_value[session.save_handler]' => 'files',
            # "php_admin_value[memory_limit]" => '128M',
          }
        }

        if a[:php][:pool]
          a[:php][:pool].each do |key, value|
            if key.include? 'php_options'
              pool_custom[:"#{key}"] = pool_custom[:"#{key}"].merge(value)
            else
              pool_custom[:"#{key}"] = value
            end
          end
        end

        if a.include? 'smtp'
          pool_custom[:php_options]['php_admin_value[sendmail_path]'] = "/usr/bin/msmtp -a #{a['user']}_#{a['name']} -t"
        end

        pool_custom.each do |key, value|
          if key == :php_options
            pool[key] = pool[key].merge(value)
          else
            pool[key] = value
          end
        end

        node.default['php-fpm']['pools'].push(pool)
      rescue Exception => e
        log 'message' do
          message "Upload PHP-FPM Cookbook.\n#{e.message}"
          level :error
        end
      end
    end

    directory "#{app_path}/backup" do
      mode      00750
      owner     a['user']
      group     a['user']
      action    :create
      recursive true
    end

    if type.include?('sites') && a.include?('nginx')
      directory "#{app_path}/docs" do
        mode      00750
        owner     a['user']
        group     a['user']
        action    :create
        recursive true
      end
      directory "#{app_path}/log" do
        mode      00755
        owner     a['user']
        group     a['user']
        action    :create
        recursive true
      end

      server_name = a['nginx']['server_name'].dup

      if node.role?('vagrant') && a['nginx']['vagrant_server_name']
        server_name.push "#{a['nginx']['vagrant_server_name']}.#{node['vagrant']['fqdn']}"
      end

      rails_nginx_vhost a['name'] do
        user             a['user']
        access_log       a['nginx']['access_log']
        error_log        a['nginx']['error_log']
        default          a['nginx']['default'] unless node.role? 'vagrant'
        deferred         a['nginx']['deferred'] unless node.role? 'vagrant'
        hidden           a['nginx']['hidden']
        disable_www      a['nginx']['disable_www']
        php a.include?   'php'
        block            a['nginx']['block']
        listen           a['nginx']['listen']
        admin            a['nginx']['admin']
        min              a['nginx']['min']
        wordpress        a['nginx']['wordpress']
        server_name      server_name
        path             app_path
        rewrites         a['nginx']['rewrites']
        file_rewrites    a['nginx']['file_rewrites']
        php_rewrites     a['nginx']['php_rewrites']
        error_pages      a['nginx']['error_pages']
        action           :create
      end
    end
  end
end

action :delete do
end
