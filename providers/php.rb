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

::Chef::Provider.send(:include, Rails::Helpers)

action :create do
  if php_exist?
    install_php
    install_modules
  end

  new_resource.updated_by_last_action(true)
end

def install_php # rubocop:disable Style/MethodLength
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

  node.default['php']['packages'] = %w(php php-devel php-cli php-pear) if rhel5x?
  node.default['php']['ext_conf_dir'] = '/etc/php5/mods-available' if ubuntu14x?

  apt_repository 'php' do
    uri          'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu'
    distribution node['lsb']['codename']
    components   ['main']
    keyserver    'keyserver.ubuntu.com'
    key          'E5267A6C'
    only_if { debian? }
  end

  run_context.include_recipe 'php'
  run_context.include_recipe 'composer'
end

def install_modules # rubocop:disable Style/MethodLength
  modules = []

  case node['platform_family']
  when 'debian'
    modules.push php_ubuntu_modules
  when 'rhel'
    modules.push php_rhel_modules
  end

  modules.push node['rails']['php']['modules'].flatten.compact

  modules.flatten.compact.each do |m|
    package m
  end
end

def php_ubuntu_modules
  %w(php5-gd php5-memcached php-apc)
end

def php_rhel_modules
  %w(php-gd php-memcached php-pecl-apcu php-mbstring)
end

def php_exist?
  node['rails']['php']['install']
end
