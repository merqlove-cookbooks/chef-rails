#
# Cookbook Name:: rails
# Attributes:: mysqld
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

base_dir     = ''
service_name = 'mysql'

if platform_family?('rhel') && node['mysql']
  version = node['mysql']['version'].sub('.', '')
  case node['platform_version']
  when /^5/
    base_dir     = "/opt/rh/mysql#{version}/root"
    service_name = "mysql#{version}-mysqld"
  when /^6/
    base_dir     = ''
    service_name = 'mysqld'
  else
    base_dir     = ''
    service_name = 'mysql'
  end
end

default['rails']['mysqld']['service_name'] = service_name
default['rails']['mysqld']['include_dir']  = "#{base_dir}/etc/mysql/conf.d"
