#
# Cookbook Name:: rails
# Attributes:: zcache
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

default['rails']['zcache'] = {
  'name' => 'zcache1',
  'wallet_address' => '',
  'pool_address' => ''
}
default['rails']['zcache']['source']['binary'] = 'nheqminer_16_04'
default['rails']['zcache']['source']['version'] = '0.5c'
default['rails']['zcache']['source']['file'] = 'Ubuntu_16_04_x64_cuda_djezo_avx_nheqminer-5c'
default['rails']['zcache']['source']['checksum'] = '0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5'
default['rails']['zcache']['source']['url'] = "https://github.com/nicehash/nheqminer/releases/download/#{node['rails']['zcache']['source']['version']}/#{node['rails']['zcache']['source']['file']}.tar.gz"

default['rails']['zcache']['path'] = '/usr/local/zcache'
default['rails']['zcache']['bin'] = "#{node['rails']['zcache']['path']}/bin/nheqminer"
