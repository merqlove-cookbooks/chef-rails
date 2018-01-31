#
# Cookbook Name:: rails
# Provider:: xmr_stak
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
    xmr_stak_create_ubuntu(new_resource)
  elsif rhel7x?
    xmr_stak_create_rhel(new_resource)
  else
    new_resource.updated_by_last_action(false)
    return
  end

  xmr_stak_service(new_resource)

  new_resource.updated_by_last_action(true)
end

action :delete do
  xmr_stak_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def xmr_stak_create_ubuntu(new_resource)
  ['cmake', 'libhwloc-dev', 'libmicrohttpd-dev', 'libssl-dev'].each do |p|
    package p
  end

  xmr_stak_install(new_resource, "cmake")
end

def xmr_stak_create_rhel(new_resource)
  ['centos-release-scl', 'cmake3', 'devtoolset-4-gcc*', 'hwloc-devel', 'libmicrohttpd-devel', 'openssl-devel', 'make'].each do |p|
    package p
  end

  execute 'enable devtoolset' do 
    command 'scl enable devtoolset-4 bash'
  end

  fix_huge_pages
  xmr_stak_install(new_resource, "cmake3")
end

def xmr_stak_install(new_resource, cmake)
  gz_filename = "v#{node['rails']['xmr_stak']['source']['version']}"
  gz_dir = "xmr-stak-#{node['rails']['xmr_stak']['source']['version']}"

  remote_file "#{Chef::Config[:file_cache_path]}/#{gz_filename}.tar.gz" do
    source   node['rails']['xmr_stak']['source']['url']
    checksum node['rails']['xmr_stak']['source']['checksum']
    action   :create
    notifies :run, 'bash[compile_xmr_from_source]', :immediately
  end

  bash 'compile_xmr_from_source' do
    cwd Chef::Config[:file_cache_path]
    code <<-EOH
      tar -xvf #{gz_filename}.tar.gz
      mkdir -p #{gz_dir}/build
      cd #{gz_dir}/build
      mkdir -p #{node['rails']['xmr_stak']['path']}
      #{cmake} -DCUDA_ENABLE=OFF -DCPU_ENABLE=ON \
      -DXMR-STAK_CURRENCY=#{node['rails']['xmr_stak']['currency']} \
      -DCMAKE_INSTALL_PREFIX=#{node['rails']['xmr_stak']['path']} -DOpenCL_ENABLE=OFF ..
      make install
    EOH
    action :nothing
  end
end

def fix_huge_pages
  line = 'vm.nr_hugepages=128'

  file = Chef::Util::FileEdit.new('/etc/sysctl.conf')
  file.insert_line_if_no_match(/#{line}/, line)
  file.write_file
end

def xmr_stak_service(new_resource)
  service new_resource.service_name do
    supports status: true, restart: true, stop: true, reload: true
    action :nothing
    ignore_failure true
  end

  template node['rails']['xmr_stak']['config'] do
    owner 'root'
    group 'root'
    mode     0o0600
    source   new_resource.config_template
    cookbook new_resource.config_template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      name: new_resource.name,
      currency: new_resource.currency,
      wallet_address: new_resource.wallet_address,
      pool_address: new_resource.pool_address,
      pool_password: new_resource.pool_password
    )
    action :create
    notifies :restart, "service[#{new_resource.service_name}]", :delayed
  end

  template node['rails']['xmr_stak']['cpu_config'] do
    owner 'root'
    group 'root'
    mode     0o0600
    source   new_resource.cpu_config_template
    cookbook new_resource.cpu_config_template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      name: new_resource.name,
    )
    action :create
    notifies :restart, "service[#{new_resource.service_name}]", :delayed
  end

  template "#{new_resource.service_path}/#{new_resource.service_name}" do
    owner 'root'
    group 'root'
    mode     0o0600
    source   new_resource.template
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      name: new_resource.name
    )
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :enable, "service[#{new_resource.service_name}]", :immediately
    notifies :restart, "service[#{new_resource.service_name}]", :delayed
  end
end

def ethereum_delete(new_resource)
  service new_resource.service_name do
    action [:stop, :delete]
  end
end
