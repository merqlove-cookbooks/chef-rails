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

use_inline_resources

require 'fileutils'

::Chef::Provider.send(:include, Rails::Helpers)

action :create do # rubocop:disable Metrics/BlockLength
  a            = new_resource.application
  type         = new_resource.type
  base_path    = node['rails']["#{type}_base_path"]
  project_path = resource_project_path(type, a)
  backup_db_path = resource_backup_db_path(type, a)
  app_path = "#{base_path}/#{project_path}"

  directory "#{base_path} #{a['name']} #{a['user']}" do
    path  "#{base_path}/#{a['user']}"
    owner a['user']
    group a['user']
    mode  0o0750
    only_if { sites?(type) }
  end

  directory app_path do
    owner     a['user']
    group     a['user']
    mode      0o0750
    recursive true
  end

  init_backup(a, type, app_path, project_path)

  init_cron(a, app_path)

  init_db(a, type, app_path, backup_db_path) if db?(a)

  if a[:delete] && a[:name] && !a['name'].empty?
    rails_nginx_vhost a['name'] do
      action :delete
      only_if { sites?(type) && nginx?(a) }
    end

    directory app_path do
      action :delete
    end

    next
  end

  if sites?(type) && nginx?(a) && !a[:enable]
    rails_nginx_vhost a['name'] do
      action :delete
    end
    next
  end

  setup_rbenv(a) if rbenv?(a)

  setup_rancher(a, app_path) if rancher?(a)

  init_smtp(a, app_path) if smtp?(a)

  setup_php(a, app_path) if php?(a)

  directory "#{app_path}/backup" do
    mode      0o0750
    owner     a['user']
    group     a['user']
    action    :create
    recursive true
  end

  setup_nginx(a, app_path) if sites?(type) && nginx?(a)

  setup_ruby_servers(a, app_path) if ruby_server?(a)

  new_resource.updated_by_last_action(true)
end

action :delete do
  new_resource.updated_by_last_action(true)
end

# Helpers

def rancher?(a)
  a.include? 'rancher'
end

def rbenv?(a)
  a.include? 'rbenv'
end

def php?(a)
  a.include? 'php'
end

def ruby_server?(a)
  a.include? 'ruby_server'
end

def smtp?(a)
  a.include? 'smtp'
end

def nginx?(a)
  a.include? 'nginx'
end

def sites?(type)
  type.include? 'sites'
end

def db?(a)
  a.include? 'db'
end

def resource_project_path(type, a)
  if sites?(type)
    "#{a['user']}/#{a['name']}"
  else
    a['name']
  end
end

def resource_backup_db_path(type, a)
  if sites?(type)
    "#{a['user']}/#{a['name']}_db"
  else
    "#{a['name']}_db"
  end
end

# Installers

def setup_rbenv(a)
  return unless a

  version  = a['rbenv']['version']
  app_gems = a['rbenv']['gems'] ||= []
  if node['rails']['rbenv']['versions'].include? version
    node.default['rails']['rbenv']['versions'][version]['gems'] ||= []
    all_gems = node['rails']['rbenv']['versions'][version]['gems'].dup

    all_gems = all_gems.push(app_gems).flatten.compact.uniq { |g| "#{g['name']} #{g['version']}" }

    node.default['rails']['rbenv']['versions'][version]['gems'] = all_gems
  else
    node.default['rails']['rbenv']['versions'][version]['gems'] = a['rbenv']['gems']
  end
end

def service_name(name)
  if rhel7x?
    "/etc/systemd/system/#{name}"
  else
    "/etc/init.d/#{name}"
  end
end

def service_base_name(name)
  if rhel7x?
    "#{name}.service"
  else
    name
  end
end

def setup_ruby_server_init(a, app_path) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  service_type = service_base_name(a['ruby_server']['type'])
  service_type_worker = service_base_name(a['ruby_server']['worker_type'])
  service_name = service_base_name("#{a['ruby_server']['type']}_#{a['name']}")
  service_name_worker = service_base_name("#{a['ruby_server']['worker_type']}_#{a['name']}")
  init_file = service_name(service_name)
  init_file_worker = service_name(service_name_worker)
  rbenv_vars_file  = "#{app_path}/.rbenv-vars"

  service service_name do
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
    ignore_failure true
  end

  service service_name_worker do
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
    ignore_failure true
  end

  if a['ruby_server']['enable']
    template rbenv_vars_file do
      action :create
      mode 0o0700
      owner           a['user']
      group           a['user']
      variables vars: a['vars']
      source 'rbenv_vars.erb'
      sensitive true
      backup false
      notifies :restart, "service[#{service_name}]", :delayed
    end

    template init_file do
      cookbook 'rails'
      source "server/#{service_type}.erb"
      owner 'root'
      group 'root'
      mode 0o0755
      variables app: a['name'],
                opts: a['ruby_server']['opts'] || {},
                user: a['user'],
                path: app_path,
                environment: a['ruby_server']['environment']
      notifies :run, 'execute[systemctl daemon-reload]', :immediately if rhel7x?
      notifies :enable, "service[#{service_name}]", :immediately
      notifies :restart, "service[#{service_name}]", :delayed
    end

    template init_file_worker do
      cookbook 'rails'
      source "server/#{service_type_worker}.erb"
      owner 'root'
      group 'root'
      mode 0o0755
      variables app: a['name'],
                opts: a['ruby_server']['worker_opts'] || {},
                user: a['user'],
                path: app_path,
                environment: a['ruby_server']['environment']
      notifies :run, 'execute[systemctl daemon-reload]', :immediately if rhel7x?
      notifies :enable, "service[#{service_name_worker}]", :immediately
      notifies :restart, "service[#{service_name_worker}]", :delayed

      only_if { a['ruby_server']['worker'] }
    end
  else
    file rbenv_vars_file do
      action :delete
    end

    file init_file do
      action :delete
      notifies :stop,    "service[#{service_name}]", :immediately
      notifies :disable, "service[#{service_name}]", :delayed
      notifies :run, 'execute[systemctl daemon-reload]', :immediately if rhel7x?
      only_if { ::FileTest.file? init_file }
    end

    file init_file_worker do
      action :delete
      notifies :stop,    "service[#{service_name_worker}]", :immediately
      notifies :disable, "service[#{service_name_worker}]", :delayed
      notifies :run, 'execute[systemctl daemon-reload]', :immediately if rhel7x?
      only_if { ::FileTest.file? init_file_worker }
    end
  end
  execute 'systemctl daemon-reload' do
    action :nothing
  end
end

def gen_tunes(a)
  tunes = (a['nginx']['tunes'] || { 'js' => false }).to_hash
  tunes['private_socket'] = true if rhel7x?
  tunes['exclude'] ||= []
  tunes
end

def gen_ssl(a, name, www=false)
  ssl = node['rails']['le'][name]
  return [nil, name] unless ssl
  server_names = (ssl['alt_names'] || []).to_a 
  server_names << ssl['cn']
  server_names.delete("www.#{ssl['cn']}") unless www
  [ssl, server_names]
end

def setup_ruby_servers(a, app_path)
  if a['ruby_server']['enable']
    tunes = gen_tunes(a)
    tunes['exclude'] = %w(jpg jpeg gif png ico svg css txt mp3 ogg mpe?g avi pdf doc docx xls xlsx ppt pptx) if tunes['exclude'].empty?

    if a['ruby_server']['no_ssl']
      a['ruby_server']['server_name'].each do |name|
        if node['rails']['le'][name]
          rails_nginx_vhost "#{a['name']}_ssl" do
            action :delete
          end
        end
      end
    else
      a['ruby_server']['server_name'].each do |name|
        ssl, server_names = gen_ssl(a, name, a['ruby_server']['www'])
        if ssl
          rails_nginx_vhost "#{a['name']}_ssl" do
            template 'nginx_ruby_crap.erb'

            user        a['user']
            type        a['ruby_server']['type']
            server_name server_names
            listen      '443'
            path        app_path
            ssl         ssl
            default_server (ssl||{})['default_server']
            disable_www a['ruby_server']['www']
            tunes       tunes
          end
        end
      end

      rails_nginx_vhost a['name'] do
        template 'nginx_ruby_crap.erb'

        user        a['user']
        type        a['ruby_server']['type']
        server_name a['ruby_server']['server_name']
        listen      a['ruby_server']['listen'] || '80'
        default_server a['ruby_server']['default_server'] || false
        path        app_path
        ssl         nil
        disable_www a['ruby_server']['www']
        tunes       tunes
      end
    end


  else
    rails_nginx_vhost a['name'] do
      action :delete
    end
  end
  setup_ruby_server_init(a, app_path)
end

def nginx_template(a, template=nil)
  case (template || a['nginx']['template'])
  when 'rancher'
    'nginx_rancher.erb'
  else
    if a['locked']
      'nginx_vhost_locked.erb'
    else
      'nginx_vhost.erb'
    end
  end
end

def setup_nginx(a, app_path, template=nil, ssl=nil) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  directory "#{app_path}/docs" do
    mode      0o0750
    owner     a['user']
    group     a['user']
    action    :create
    recursive true
  end
  directory "#{app_path}/log" do
    mode      0o0755
    owner     a['user']
    group     a['user']
    action    :create
    recursive true
  end

  tunes = gen_tunes(a)

  template_path = if template
    nginx_template(a, template)
  else 
    nginx_template(a)
  end

  server_name = a['nginx']['server_name'].dup

  if node.role?('vagrant') && a['nginx']['vagrant_server_name']
    server_name.push "#{a['nginx']['vagrant_server_name']}.#{node['vagrant']['fqdn']}"
  end

  ssl = if a['nginx']['ssl']
    data_bag = ::Chef::EncryptedDataBagItem.load(node['rails']['d']['users'], a['user'], load_secret) || {} # rubocop:disable Style/IndentationWidth
    (a['nginx']['ssl']).merge((data_bag['ssl'] || {})[a['name']] || {}) if data_bag
  end # rubocop:disable Lint/EndAlignment

  server_names = server_name
  ssl, server_names = gen_ssl(a, a['name'], a['nginx']['disable_www']) if ssl.nil?

  rails_nginx_vhost a['name'] do
    user             a['user']
    access_log       a['nginx']['access_log']
    error_log        a['nginx']['error_log']
    default          a['nginx']['default'] unless node.role? 'vagrant'
    deferred         a['nginx']['deferred'] unless node.role? 'vagrant'
    hidden           a['nginx']['hidden']
    disable_www      a['nginx']['disable_www']
    php              a.include?('php')
    seo_url          a['nginx']['seo_url']
    block            a['nginx']['block']
    listen           a['nginx']['listen']
    ssl              ssl
    engine           a['nginx']['engine']
    server_name      server_name
    path             app_path
    path_suffix      a['nginx']['path_suffix']
    auth_basic       a['nginx']['auth_basic']
    auth_basic_user_file a['nginx']['auth_basic_user_file']
    rewrites         a['nginx']['rewrites']
    file_rewrites    a['nginx']['file_rewrites']
    php_rewrites     a['nginx']['php_rewrites']
    error_pages      a['nginx']['error_pages']
    template         template_path
    action           :create
    tunes            tunes
  end
end

def setup_rancher(a, app_path)
  setup_nginx(a, app_path, 'rancher')
end

def setup_php(a, app_path)
  return unless a

  node.default['rails']['php']['install'] = true
  node.default['rails']['php']['modules'].push a['php']['modules']

  directory "/var/lib/php/session/#{a['user']}_#{a['name']}" do
    owner     a['user']
    group     a['user']
    mode      0o0700
    action    :create
    recursive true
  end

  fill_php_config(a, app_path)
end

def init_smtp(a, app_path)
  node.default['msmtp']['accounts'][a['user']][a['name']]          = a[:smtp]
  node.default['msmtp']['accounts'][a['user']][a['name']][:syslog] = 'on'
  node.default['msmtp']['accounts'][a['user']][a['name']][:log]    = "#{app_path}/log/msmtp.log"
end

def init_db(a, type, app_path, backup_db_path)
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

def init_backup(a, type, app_path, project_path)
  return unless a['backup']
  rails_backup a['name'] do
    path        "#{type}/#{project_path}"
    include     [app_path]
    exclude     ["#{app_path}/backup"]
    archive_dir "/tmp/da-#{a['user']}-#{a['name']}"
    temp_dir    "/tmp/dt-#{a['user']}-#{a['name']}"
  end
end

def init_cron(a, app_path) # rubocop:disable Metrics/MethodLength
  return unless a['cron']
  a['cron'].each do |cron|
    environment = cron[:environment] || {}
    environment['PHP'] = "#{node['php']['prefix_dir']}/bin/#{node['php']['bin']}" if php?(a)
    if rbenv?(a)
      environment.merge!('RBENV_ROOT' => node['rbenv']['root_path'],
                         'RBENV_SHIMS' => '$RBENV_ROOT/shims',
                         'RBENV_BIN' => '$RBENV_ROOT/bin',
                         'PATH' => '/usr/local/bin:/usr/local/lib:$RBENV_SHIMS:$RBENV_BIN:$PATH')
    end

    rails_cron "#{a[:name]}-#{cron[:name] || 'default'}" do
      interval    cron[:interval]
      minute      cron[:minute]
      hour        cron[:hour]
      day         cron[:day]
      month       cron[:month]
      weekday     cron[:weekday]
      user        a[:user]
      command     cron[:command]
      mailto      cron[:mailto]
      path        cron[:path]
      home        cron[:home]
      shell       cron[:shell]
      environment environment.merge('APP_PATH' => app_path,
                                    'POSTGRESQL_BIN' => "/usr/pgsql-#{node['postgresql']['version']}/bin")

      action :create
    end
  end
end

# Methods

def fill_php_config(a, app_path) # rubocop:disable Metrics/MethodLength
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
      pool_custom[:"#{key}"] = if key.include? 'php_options'
                                 pool_custom[:"#{key}"].merge(value)
                               else
                                 value
                               end
    end
  end

  if smtp?(a)
    pool_custom[:php_options]['php_admin_value[sendmail_path]'] = "#{node['msmtp']['binary']} -a #{a['name']} -t"
  end

  pool_custom.each do |key, value|
    pool[key] = if key == :php_options
                  pool[key].merge(value)
                else
                  value
                end
  end

  node.default['php-fpm']['pools'] << pool
end
