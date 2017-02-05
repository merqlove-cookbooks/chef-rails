#
# Cookbook Name:: rails
# Recipe:: le
#
# Copyright (C) 2017 Alexander Merkulov
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

include_recipe 'acme'

directory '/etc/nginx/ssl' do
  owner 'root'
  group 'root'
  mode  0o0644
  recursive true
end

node['rails']['le'].each do |site, le|
  next unless le['cn']

  acme_certificate le['cn'] do
    alt_names le['alt_names']
    method    'http'
    key       "/etc/nginx/ssl/#{site}.key"
    fullchain "/etc/nginx/ssl/#{site}.pem"
    wwwroot   le['wwwroot']
    notifies :restart, "service[nginx]", :immediate
  end
end