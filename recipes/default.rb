#
# Cookbook Name:: rails
# Recipe:: default
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

case node['platform_family']
when "debian"
  node.default['postgresql']['enable_pgdg_apt'] = true
when 'rhel', 'fedora', 'suse'
  node.default['postgresql']['enable_pgdg_yum'] = true
  version = node['postgresql']['version']
  version_merge = version.gsub /\./, '' 
  node.default['postgresql']['dir'] = "/var/lib/pgsql/#{version}/data"
  node.default['postgresql']['client']['packages'] = ["postgresql#{version_merge}", "postgresql#{version_merge}-devel"]
  node.default['postgresql']['server']['packages'] = ["postgresql#{version_merge}-server"]
  node.default['postgresql']['server']['service_name'] = "postgresql-#{version}"
  node.default['postgresql']['contrib']['packages'] = ["postgresql#{version_merge}-contrib"]
end

include_recipe "rails::rbenv"

directory node['rails']['apps_base_path'] do
  mode      '0755'
  owner     node['rails']['user']['deploy']
  group     node['rails']['user']['deploy']
  action    :create
  recursive true
end

directory node['rails']['sites_base_path'] do
  mode      '0755'
  owner     node['rails']['user']['deploy']
  group     node['rails']['user']['deploy']
  action    :create
  recursive true
end

include_recipe "rails::apps"
include_recipe "rails::database_admin"

