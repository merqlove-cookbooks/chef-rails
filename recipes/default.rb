#
# Cookbook Name:: rails
# Recipe:: default
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

service 'memcached' do
  action [:enable, :start]
  only_if { node['recipes'].include?('memcached::default') }
end

directory node['rails']['apps_base_path'] do
  mode      00755
  owner     node['rails']['user']['deploy']
  group     node['rails']['user']['deploy']
  action    :create
  recursive true
end

directory node['rails']['sites_base_path'] do
  mode      00755
  owner     node['rails']['user']['deploy']
  group     node['rails']['user']['deploy']
  action    :create
  recursive true
end
