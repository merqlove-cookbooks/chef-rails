#
# Cookbook Name:: rails
# Provider:: zcache
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
  if ubuntu16x?
    zcache_create_ubuntu(new_resource)
  else
    new_resource.updated_by_last_action(false)
    return
  end

  nheqminer_service(new_resource)

  new_resource.updated_by_last_action(true)
end

action :delete do
  zcache_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def zcache_create_ubuntu(new_resource)
  ['cmake', 'libboost-all-dev'].each do |p|
    package p
  end

  gz_dir = "nheqminer"

  git "#{Chef::Config[:file_cache_path]}/#{gz_dir}" do
    repository node['rails']['zcache']['git_repo']
    enable_submodules true
    action :sync
    notifies :run, 'bash[compile_nheq_from_source]', :immediately
  end

  bash 'compile_nheq_from_source' do
    cwd Chef::Config[:file_cache_path]
    code <<-EOH
      cd #{gz_dir}/#{gz_dir}
      mkdir build
      cd build
      cmake -DXENON=1 ..
      make      
      mkdir -p #{node['rails']['zcache']['path']}/bin
      mv #{node['rails']['zcache']['binary']} #{node['rails']['zcache']['bin']}
      chmod +x #{node['rails']['zcache']['bin']}
    EOH
    action :nothing
  end
end

def nheqminer_service(new_resource)
  service new_resource.service_name do
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
    ignore_failure true
  end

  template "#{new_resource.service_path}/#{new_resource.service_name}" do
    owner 'root'
    group 'root'
    mode     0o0600
    source   new_resource.template
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      name: new_resource.name,
      wallet_address: new_resource.wallet_address,
      pool_address: new_resource.pool_address
    )
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :enable, "service[#{new_resource.service_name}]", :immediately
    notifies :restart, "service[#{new_resource.service_name}]", :delayed
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end
end

def zcache_delete(new_resource)
  service new_resource.service_name do
    action [:stop, :delete]
  end
end
