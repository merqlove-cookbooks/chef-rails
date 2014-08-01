#
# Cookbook Name:: rails
# Recipe:: apps
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

# Fix nginx
file "#{node['nginx']['dir']}/conf.d/default.conf" do
  action :delete
end

node.default['rails']['rbenv']['versions'] = {}
node.default['rails']['php']['install']    = false
node.default['rails']['php']['modules']    = []
node.default['php-fpm']['pools']           = []

# Useful databases
node.default['rails']['databases'] = {}

node['rails']['sites'].each do |k, a|
  rails_app k do
    application a
    type 'sites'
  end
end

node['rails']['apps'].each do |k, a|
  rails_app k do
    application a
    type 'apps'
  end
end

rails_rbenv 'initialize'
rails_php 'initialize'
rails_php_fpm 'initialize'

# Sites cleanup
if node['rails']['sites'].count > 0
  execute 'deny site groups from write' do
    command "chmod -R g-w #{node['rails']['sites_base_path']}/*/*/docs"
    action :run
  end

  execute 'deny site others from read' do
    command "chmod -R o-rwx #{node['rails']['sites_base_path']}/*/*/docs"
    action :run
  end
end

include_recipe 'rails::databases'

rails_backup 'system' do
  main true
end

msmtp_system   'initialize base msmtp account'
msmtp_accounts 'initialize user msmtp accounts'
include_recipe 'rails::cleanup'
