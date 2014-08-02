#
# Cookbook Name:: rails
# Provider:: php_fpm
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

::Chef::Provider.send(:include, Rails::Helpers)

action :create do
  # PHP pools
  if php_fpm?
    node.default['php-fpm']['skip_repository_install'] = true if rhel?
    run_context.include_recipe 'php-fpm::install'
    run_context.include_recipe 'php-fpm::configure'

    template "#{node['php']['ext_conf_dir']}/php_fix.ini" do
      owner 'root'
      group 'root'
      mode 00755
      source 'php_fix.erb'
      notifies :restart, 'service[php-fpm]', :delayed
    end

    cleanup_php_fpm

    directory '/var/lib/php/session' do
      owner 'root'
      group 'root'
      mode 00777
    end
  else
    stop_php_fpm
  end

  new_resource.updated_by_last_action(true)
end

# Makers

def cleanup_php_fpm # rubocop:disable Style/MethodLength
  return unless ::Dir.exist? node['php-fpm']['pool_conf_dir']

  deleted = false

  ::Dir.foreach(node['php-fpm']['pool_conf_dir']) do |pool|
    next if pool == '.' || pool == '..'
    if pool.include? '.conf'
      unless hash_in_array?(node['php-fpm']['pools'], pool.gsub(/\.conf/, '')) # rubocop:disable Style/BlockNesting
        ::File.delete("#{node['php-fpm']['pool_conf_dir']}/#{pool}")
        deleted = true
      end
    end
  end

  service 'php-fpm' do
    action [:restart]
    only_if { deleted }
  end
end

def stop_php_fpm
  return unless ::Dir.exist? node['php-fpm']['pool_conf_dir']

  ::Dir.foreach(node['php-fpm']['pool_conf_dir']) do |pool|
    next if pool == '.' || pool == '..'
    if pool.include?('.conf') && !pool.include?('www.conf')
      ::File.delete("#{node['php-fpm']['pool_conf_dir']}/#{pool}")
    end
  end
  service 'php-fpm' do
    action [:disable, :stop]
  end
end
