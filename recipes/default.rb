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

ruby_exists = search(:node, "roles:base_ruby AND name:#{node.name}")

if ruby_exists.count > 0
  case node[:platform]
  when "redhat", "centos", "amazon", "oracle"
    package "patch"
    package "automake"
    package "libyaml-devel"
    package "libffi-devel"
    package "libtool"
  when "debian", "ubuntu"
    # TODO: Add same packages
  end
  node.default['rails']['ruby'] = true
else
  case node[:platform]
  when "redhat", "centos", "amazon", "oracle"
    package "openssl-devel"
    package "zlib-devel"
    package "readline-devel"
    package "libxml2-devel"
    package "libxslt-devel"
    package "patch"
    package "automake"
    package "libyaml-devel"
    package "libffi-devel"
    package "libtool"
  when "debian", "ubuntu"
    # TODO: Add same packages
  end
  node.default['rails']['ruby'] = false
end

service "memcached" do
  action [:enable, :start]
end

case node['platform_family']
when "debian"
  node.default['postgresql']['enable_pgdg_apt'] = true
when 'rhel', 'fedora', 'suse'
  node.default['postgresql']['enable_pgdg_yum'] = true
end

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
