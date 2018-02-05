#
# Cookbook Name:: rails
# Attributes:: xmr_stak
#
# Copyright (C) 2014 Alexander Merkulov
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

default['rails']['xmr_stak'] = {
  'name' => node['hostname'],
  'wallet_address' => '',
  'currency' => 'monero',
  'pool_address' => 'xmr.pool.minergate.com:45560',
  'pool_password' => 'x'
}

default['rails']['xmr_stak']['path'] = '/usr/local/xmr_stak'
default['rails']['xmr_stak']['bin'] = "#{node['rails']['xmr_stak']['path']}/bin/xmr-stak"
default['rails']['xmr_stak']['config'] = "#{node['rails']['xmr_stak']['path']}/config.txt"
default['rails']['xmr_stak']['cpu_config'] = "#{node['rails']['xmr_stak']['path']}/cpu.config.txt"
default['rails']['xmr_stak']['source']['version'] = '2.2.0'
default['rails']['xmr_stak']['source']['checksum'] = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
default['rails']['xmr_stak']['source']['url'] = "https://github.com/fireice-uk/xmr-stak/archive/v#{node['rails']['xmr_stak']['source']['version']}.tar.gz"
