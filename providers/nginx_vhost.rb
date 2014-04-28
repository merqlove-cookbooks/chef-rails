#
# Cookbook Name:: rails
# Provider:: nginx_vhost
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

action :create do
  listen = new_resource.listen
  # locations = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:locations].to_hash.merge(new_resource.locations).to_json)
  # options = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:options].to_hash.merge(new_resource.options).to_json)
  # upstream = JSON.parse(node.send(new_resource.precedence)[:nginx_conf][:upstream].to_hash.merge(new_resource.upstream).to_json)
  server_name = new_resource.server_name || new_resource.name
  name = new_resource.name

  # if site_type == :dynamic
  #   locations.each do |name, location|
  #     if options['try_files']
  #       options['try_files'] << " #{name}" if name.index('@') == 0
  #     end
  #   end

  #   if socket && locations.has_key?('/')
  #     locations['/']['proxy_pass'] = node[:nginx_conf][:pre_socket].to_s + socket.to_s
  #   end
  # end

#   if new_resource.ssl
#     ssl_name = if new_resource.ssl['name']
#       new_resource.ssl['name']
#     else
#       conf_name
#     end

#     directory "#{node[:nginx][:dir]}/ssl" do
#       owner node[:nginx][:user] 
#       group node[:nginx][:group]
#       mode '0755'
#     end

#     file "#{node[:nginx][:dir]}/ssl/#{ssl_name}.public.crt" do
#       owner node[:nginx][:user] 
#       group node[:nginx][:group]
#       mode '0640'
#       content  <<-EOH
# # Managed by Chef.  Local changes will be overwritten.
# #{new_resource.ssl['public']}
# EOH
#     end

#     file "#{node[:nginx][:dir]}/ssl/#{ssl_name}.private.key" do
#       owner node[:nginx][:user] 
#       group node[:nginx][:group]
#       mode '0640'
#       content <<-EOH
# # Maintained by Chef.  Local changes will be overwritten.
# #{new_resource.ssl['private']}
# EOH
#     end

#     ssl = {
#       :certificate => "#{node[:nginx][:dir]}/ssl/#{ssl_name}.public.crt",
#       :certificate_key => "#{node[:nginx][:dir]}/ssl/#{ssl_name}.private.key"
#     }
#   end

  test_nginx = execute "test-nginx-conf-#{name}-create" do
    action :nothing
    command "#{node[:nginx][:binary]} -t"
    only_if { new_resource.auto_enable_site }
    notifies :reload, 'service[nginx]', new_resource.reload
  end

  template "#{node[:nginx][:dir]}/sites-available/#{name}" do
    owner "root" 
    group "root"
    mode 00644
    source(new_resource.template || 'nginx_vhost.erb')
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : 'rails'
    variables(
      :block =>  new_resource.block,
      # :options =>  options,
      # :upstream => upstream,
      :listen => listen,
      # :locations =>  locations,
      :default => new_resource.default,
      :deferred => new_resource.deferred,
      :disable_www => new_resource.disable_www,
      :access_log => new_resource.access_log,
      :error_log => new_resource.error_log,
      :name => name,
      :admin => new_resource.admin,
      :path =>  new_resource.path,      
      :server_name => server_name,
      :php =>  new_resource.php,
      :min =>  new_resource.min,
      :wordpress =>  new_resource.wordpress,
      :rewrites =>  new_resource.rewrites,
      :file_rewrites =>  new_resource.file_rewrites,
      :php_rewrites => new_resource.php_rewrites,
      :error_pages => new_resource.error_pages,
      :hidden => new_resource.hidden,
      :ssl => new_resource.ssl
    )
    notifies :run, test_nginx, new_resource.reload
  end

  nginx_site name do
    enable true
    only_if { new_resource.auto_enable_site }
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

  file "#{node[:nginx][:dir]}/sites-available/#{name}" do
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