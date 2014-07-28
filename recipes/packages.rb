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

ruby_exists = 0

if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else
  ruby_exists = search(:node, "roles:base_ruby AND name:#{node.name}")
end

package 'patch'
package 'automake'
package 'libtool'

if ruby_exists.count > 0
  case node['platform_family']
    when 'rhel'
      package 'libyaml-devel'
      package 'libffi-devel'
    when 'debian'
      package 'libyaml-dev'
      package 'libffi-dev'
  end
  node.default['rails']['ruby'] = true
else
  case node['platform_family']
    when 'rhel'
      package 'openssl-devel'
      package 'zlib-devel'
      package 'readline-devel'
      package 'libxml2-devel'
      package 'libxslt-devel'
      package 'libyaml-devel'
      package 'libffi-devel'
    when 'debian'
      package 'libssl-dev'
      package 'zlib1g-dev'
      package 'libreadline6-dev'
      package 'libxml2-dev'
      package 'libxslt1-dev'
      package 'libyaml-dev'
      package 'libffi-dev'
  end
  node.default['rails']['ruby'] = false
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
    package 'db4-utils'
    package 'db4'
end
