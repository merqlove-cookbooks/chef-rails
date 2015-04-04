#
# Cookbook Name:: rails
# Recipe:: users
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
#

if node['rails']['apps'] || node['rails']['sites']
  users = []
  node['rails']['apps'].each do |_k, a|
    users.push a['user']
  end
  node['rails']['sites'].each do |_k, a|
    users.push a['user']
  end
  users = users.unshift(node['rails']['user']['deploy']).uniq.compact

  # Reload OHAI 7
  ohai 'reload_passwd' do
    action :nothing
    plugin 'etc'
  end

  rails_users 'references_for_users' do
    users  users
    notifies :reload, 'ohai[reload_passwd]', :immediately
  end
end
