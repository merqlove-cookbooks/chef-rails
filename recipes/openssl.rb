#
# Cookbook Name:: rails
# Recipe:: openssl
#
# Copyright (C) 2016 Alexander Merkulov
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

::Chef::Recipe.send(:include, Rails::Helpers)

case node['platform_family']
when 'debian'
  include_recipe 'openssl::upgrade'
when 'rhel'
  include_recipe 'openssl::upgrade'
end

if node['rails']['nginx']['dhparam']
  execute 'ssl_dhparam_fix' do
    command "openssl dhparam -out #{node['rails']['openssl']['dhparam_file']} 4096"
    cwd     node['rails']['openssl']['dhparam_dir']
    user    'root'
    creates node['rails']['openssl']['dhparam_path']
    group   'root'
    notifies :run, 'service[nginx]', :delayed
  end
  node.default['nginx']['extra_configs'] = node['nginx']['extra_configs'].merge(node['rails']['nginx']['dhparam_configs'])
end

node.default['nginx']['extra_configs'] = node['nginx']['extra_configs'].merge(node['rails']['nginx']['extra_configs'])
