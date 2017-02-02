#
# Cookbook Name:: rails
# Provider:: nginx_vhost
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

use_inline_resources

action :create do # rubocop:disable Metrics/BlockLength
  listen = new_resource.listen
  # locations = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:locations].to_hash.merge(new_resource.locations).to_json)
  # options = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:options].to_hash.merge(new_resource.options).to_json)
  # upstream = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:upstream].to_hash.merge(new_resource.upstream).to_json)
  server_name = new_resource.server_name || new_resource.name
  name = new_resource.name
  auto_enable_site = new_resource.auto_enable_site

  # if site_type == :dynamic
  #   locations.each do |name, location|
  #     if options['try_files']
  #       options['try_files'] << " #{name}" if name.index('@') == 0
  #     end
  #   end
  #
  #   if socket && locations.has_key?('/')
  #     locations['/']['proxy_pass'] = node[:nginx_conf][:pre_socket].to_s + socket.to_s
  #   end
  # end

  ssl = if new_resource.ssl
    ssl_name = if new_resource.ssl['name'] # rubocop:disable Style/IndentationWidth
      new_resource.ssl['name'] # rubocop:disable Style/IndentationWidth
    else # rubocop:disable Style/ElseAlignment
      name
    end # rubocop:disable Lint/EndAlignment

    directory "#{node['nginx']['dir']}/ssl/#{ssl_name}" do
      owner node['nginx']['user']
      group node['nginx']['group']
      mode '0755'
      recursive true
    end

    file "#{node['nginx']['dir']}/ssl/#{ssl_name}/public.crt" do
      owner node['nginx']['user']
      group node['nginx']['group']
      mode '0640'
      content  new_resource.ssl['public'].gsub('\n', "\n")
      notifies :restart, 'service[nginx]', new_resource.reload
    end

    file "#{node['nginx']['dir']}/ssl/#{ssl_name}/private.key" do
      owner node['nginx']['user']
      group node['nginx']['group']
      mode '0640'
      content new_resource.ssl['private'].gsub('\n', "\n")
      notifies :restart, 'service[nginx]', new_resource.reload
    end

    file "#{node['nginx']['dir']}/ssl/#{ssl_name}/ca.crt" do
      owner node['nginx']['user']
      group node['nginx']['group']
      mode '0640'
      content new_resource.ssl['ca'].gsub('\n', "\n")
      notifies :restart, 'service[nginx]', new_resource.reload
    end

    {
      certificate: "#{node['nginx']['dir']}/ssl/#{ssl_name}/public.crt",
      certificate_key: "#{node['nginx']['dir']}/ssl/#{ssl_name}/private.key",
      ca: "#{node['nginx']['dir']}/ssl/#{ssl_name}/ca.crt",
      manual: new_resource.ssl['manual'],
      default: new_resource.ssl['default'],
      default_server: new_resource.ssl['default_server']
    }
  end # rubocop:disable Lint/EndAlignment

  auth_basic = (new_resource.auth_basic && !new_resource.auth_basic.empty?)
  auth_file = if auth_basic
                auth_basic_user_file(
                  new_resource.auth_basic_user_file,
                  new_resource.path,
                  new_resource.user
                )
              else
                new_resource.auth_basic_user_file
              end

  test_nginx = execute "test-nginx-conf-#{name}-create" do
    action   :nothing
    command  "#{node['nginx']['binary']} -t"
    only_if  { new_resource.auto_enable_site }
    notifies :reload, 'service[nginx]', new_resource.reload
  end

  template "#{node['nginx']['dir']}/sites-available/#{name}" do # rubocop:disable Metrics/BlockLength
    owner 'root'
    group 'root'
    mode 0o0644
    source new_resource.template
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables block:         new_resource.block,
              # options:     options,
              # upstream:    upstream,
              listen:        listen,
              # locations:   locations,
              default:       new_resource.default,
              deferred:      new_resource.deferred,
              disable_www:   new_resource.disable_www,
              access_log:    new_resource.access_log,
              error_log:     new_resource.error_log,
              name:          name,
              user:          new_resource.user,
              path:          new_resource.path,
              path_suffix:   new_resource.path_suffix,
              server_name:   server_name,
              tunes:         new_resource.tunes,
              php:           new_resource.php,
              seo_url:       new_resource.seo_url,
              engine:        new_resource.engine,
              type:          new_resource.type,
              rewrites:      new_resource.rewrites,
              auth_basic_name: new_resource.auth_basic,
              auth_basic:    auth_basic,
              auth_basic_user_file: auth_file,
              file_rewrites: new_resource.file_rewrites,
              php_rewrites:  new_resource.php_rewrites,
              error_pages:   new_resource.error_pages,
              hidden:        new_resource.hidden,
              ssl:           ssl,
              vagrant:       node.role?('vagrant')

    notifies :run, test_nginx, new_resource.reload
  end

  nginx_site name do
    enable true
    only_if { auto_enable_site }
  end

  # link "#{node[:nginx][:dir]}/sites-enabled/#{name}" do
  #   to "#{node[:nginx][:dir]}/sites-available/#{name}"
  #   only_if { new_resource.auto_enable_site }
  #   notifies :run, test_nginx, new_resource.reload
  # end

  new_resource.updated_by_last_action(true)
end

action :delete do
  name = new_resource.name

  nginx_site name do
    enable false
  end

  file "#{node['nginx']['dir']}/sites-available/#{name}" do
    action :delete
    # notifies :restart, 'service[nginx]', new_resource.reload
  end

  # if node[:nginx_conf][:delete][:ssl]
  #   unless new_resource.ssl && !new_resource.ssl['delete']
  #     ssl_name = if new_resource.ssl && new_resource.ssl['name']
  #       new_resource.ssl['name']
  #     else
  #       conf_name
  #     end

  #     file "#{node[:nginx][:dir]}/ssl/#{ssl_name}.public.crt" do
  #       action :delete
  #     end

  #     file "#{node[:nginx][:dir]}/ssl/#{ssl_name}.private.key" do
  #       action :delete
  #     end
  #   end
  # end

  new_resource.updated_by_last_action(true)
end

action :enable do
  name = new_resource.name

  nginx_site name do
    enable true
  end

  new_resource.updated_by_last_action(true)
end

action :disable do
  name = new_resource.name

  nginx_site name do
    enable false
  end

  new_resource.updated_by_last_action(true)
end

def auth_basic_user_file(auth_basic_user_file, path, user)
  if auth_basic_user_file && ::File.exist?(auth_basic_user_file)
    auth_basic_user_file
  elsif auth_basic_user_file && ::File.exist?(::File.join(path, auth_basic_user_file))
    ::File.join(path, auth_basic_user_file)
  else
    directory "#{path}/conf" do
      mode      0o0770
      owner     user
      group     user
      action    :create
    end
    ::File.join(path, 'conf', 'htpasswd')
  end
end
