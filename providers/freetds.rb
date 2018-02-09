#
# Cookbook Name:: rails
# Provider:: freetds
#
# Copyright (C) 2018 Alexander Merkulov
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

action :create do
  case node['rails']['freetds']['install_method']
  when 'package'
    install_package(new_resource)
  when 'source'
    install_source(new_resource)
  else 
    new_resource.updated_by_last_action(false)
    return
  end 

  directory node['rails']['freetds']['dir'] do
    owner 'root'
    group 'root'
    recursive true
  end

  template ::File.join(node['rails']['freetds']['dir'], 'freetds.conf') do
    source new_resource.template
    owner 'root'
    group 'root'
    mode '0644'
  end

  new_resource.updated_by_last_action(true)
end

action :delete do
  new_resource.updated_by_last_action(true)
end

def install_package(new_resource)
  node['rails']['freetds']['packages'].each do |pkg|
    package pkg
  end
end

def install_source(new_resource)
  version = node['rails']['freetds']['version']
  freetds_url = node['rails']['freetds']['url'] ||
                "ftp://ftp.freetds.org/pub/freetds/stable/freetds-#{version}.tar.gz"
  configure_options = "--with-tdsver=#{node['rails']['freetds']['tds_version']} #{'--disable-odbc' unless node['rails']['freetds']['odbc']}"

  remote_file "#{Chef::Config[:file_cache_path]}/freetds-#{version}.tar.gz" do
    action :create_if_missing
    backup false
    source freetds_url
    checksum node['rails']['freetds']['checksum'] if node['rails']['freetds']['checksum']
  end

  bash 'build freetds' do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar zxf freetds-#{version}.tar.gz
      (cd freetds-#{version} && CFLAGS='-fPIC' ./configure #{configure_options})
      (cd freetds-#{version} && make && make install)
    EOF
    not_if 'which tsql'
  end
end
