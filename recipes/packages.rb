#
# Cookbook Name:: rails
# Recipe:: packages
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

::Chef::Recipe.send(:include, Rails::Helpers)

%w(patch automake libtool).each do |p|
  package p
end

# Install Db4
case node['platform_family']
when 'debian'
  if ubuntu14x?
    package 'libdb5.3'
  else
    package 'libdb5.1'
  end
  package 'db-util'
when 'rhel'
  %w(db4-utils db4).each do |p|
    package p
  end
end
