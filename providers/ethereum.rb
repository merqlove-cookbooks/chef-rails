#
# Cookbook Name:: rails
# Provider:: ethereum
#
# Copyright (C) 2018 Alexander Merkulov
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

use_inline_resources

::Chef::Provider.send(:include, Rails::Helpers)

action :create do
  unless ubuntu16x?
    new_resource.updated_by_last_action(false)
    return
  end

  ethereum_create(new_resource)
  ethereum_service(new_resource)

  new_resource.updated_by_last_action(true)
end

action :delete do
  ethereum_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def ethereum_create(new_resource)
  apt_repository 'ethereum' do
    uri          'http://ppa.launchpad.net/ethereum/ethereum/ubuntu'
    distribution node['lsb']['codename']
    components   ['main']
    only_if { debian? }
  end
  apt_repository 'ethereum-dev' do
    uri          'http://ppa.launchpad.net/ethereum/ethereum-dev/ubuntu'
    distribution node['lsb']['codename']
    components   ['main']
    only_if { debian? }
  end

  package 'ethereum'
end

def ethereum_service(new_resource)
  service new_resource.service_name do
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
    ignore_failure true
  end

  wallet = wallet_get(new_resource)

  template "#{new_resource.service_path}/#{new_resource.service_name}" do
    owner 'root'
    group 'root'
    mode     0o0600
    source   new_resource.template
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      name: new_resource.name,
      wallet: wallet,
      log_path: new_resource.log_path
    )
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :enable, "service[#{service_name}]", :immediately
    notifies :restart, "service[#{service_name}]", :delayed
  end
end

def wallet_get(new_resource)
  secret = load_secret
  root = ::Chef::EncryptedDataBagItem.load("ethereum", new_resource.wallet, secret)
  if root
    root['value']
  else
    ''
  end
end

def ethereum_delete(new_resource)
  service new_resource.service_name do
    action [:stop, :delete]
  end
end
