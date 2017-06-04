#
# Cookbook Name:: rails
# Recipe:: nfs
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

hosts_file = Chef::Util::FileEdit.new('/etc/hosts')

exports = (node['rails']['nfs']['exports'] || {})

execute 'echo "" > /etc/exports' do
  only_if { exports.size > 0 }
end

exports.each do |k, v|
  directory k do
    owner 'nfsnobody'
    group 'nfsnobody'
    mode 0o0777
  end

  options = []
  hosts = nil

  if v['search']
    nodes = search(:node, v['search'])
    hosts = nodes.map do |n|
      host = "#{n['cloud_v2']['public_ipv4']} #{n['cloud']['vm_name']}"
      hosts_file.insert_line_if_no_match(/\s#{n['cloud']['vm_name']}/, host)
      n['cloud']['vm_name']
    end
    hosts << node['rails']['nfs']['admin_ip'] if node['rails']['nfs']['admin_ip']
  end

  network = v['network'] || '*'
  custom_options = v['options'] || 'no_subtree_check'

  options << custom_options

  nfs_export k do
    writeable (v['writeable'] && true)
    sync (v['sync'] && true)
    options options.flatten
    network (hosts || network)
  end
end

hosts_file.write_file
