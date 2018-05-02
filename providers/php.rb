#
# Cookbook Name:: rails
# Provider:: php
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

::Chef::Provider.send(:include, Rails::Helpers)

action :install do
  install_php if php_exist?

  new_resource.updated_by_last_action(true)
end

action :modules do
  install_modules if php_exist?

  new_resource.updated_by_last_action(true)
end

def install_php
  case node['platform_family']
  when 'rhel'
    %w(openssl-devel zlib-devel readline-devel libxml2-devel libxslt-devel libyaml-devel libffi-devel).each do |p|
      package p
    end
  when 'debian'
    %w(libssl-dev zlib1g-dev libreadline6-dev libxml2-dev libxslt1-dev libyaml-dev libffi-dev).each do |p|
      package p
    end
  end

  node.default['php']['ext_conf_dir'] = '/etc/php5/mods-available' if ubuntu14x?

  apt_repository 'php' do
    uri          'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu'
    distribution node['lsb']['codename']
    components   ['main']
    keyserver    'keyserver.ubuntu.com'
    key          'E5267A6C'
    not_if { ubuntu16x? }
  end
end

def install_modules
  modules = []

  case node['platform_family']
  when 'debian'
    modules.push php_ubuntu_modules
  when 'rhel'
    modules.push php_rhel_modules
  end

  service 'php-fpm' do
    service_name node['php-fpm']['service']
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
  end

  modules.push node['rails']['php']['modules'].flatten.compact

  modules.flatten.compact.uniq.each do |m|
    package m do
      action :install
      notifies :reload, 'service[php-fpm]', :delayed
    end
  end
end

def php_ubuntu_modules
  return %w(php5-gd php5-memcached php-apcu) unless ubuntu16x?
  %w(php-gd php-memcached php-apc)  
end

def php_rhel_modules
  %w(php-gd php-memcached php-pecl-apcu php-mbstring)
end
