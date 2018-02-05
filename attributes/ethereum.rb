#
# Cookbook Name:: rails
# Attributes:: ethereum
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

default['rails']['ethereum'] = {
  'name' => 'ether1',
  'wallet_address' => '',
  'pool_address' => ''
}
default['rails']['ethereum']['git_repo'] = 'https://github.com/ethereum/cpp-ethereum.git'
default['rails']['ethereum']['source']['version'] = '1.7.3'
default['rails']['ethereum']['source']['checksum'] = 'a3b89d9428402152c3d782e3289ddc81c57ee3cb02a77c583e9e3edc6f6e3382'
# default['rails']['ethereum']['source']['url'] = "https://github.com/ethereum/go-ethereum/archive/v#{node['rails']['ethereum']['source']['version']}.tgz"
default['rails']['ethereum']['source']['url'] = "https://github.com/ethereum/cpp-ethereum/archive/develop.zip"

default['rails']['ethereum']['path'] = '/usr/local/ethereum'
default['rails']['ethereum']['bin'] = "#{node['rails']['ethereum']['path']}/bin/ethminer"
