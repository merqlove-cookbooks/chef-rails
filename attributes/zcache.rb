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
default['rails']['zcache']['binary'] = 'nheqminer_16_04'
default['rails']['zcache']['version'] = '0.5c'
default['rails']['zcache']['file'] = 'Ubuntu_16_04_x64_cuda_djezo_avx_nheqminer-5c'
default['rails']['zcache']['checksum'] = '7f7ae8c448307f7632ad48f50e7663a7191b65d876f2fe502bb9f09422e1e8b3'
default['rails']['zcache']['url'] = "https://github.com/nicehash/nheqminer/releases/download/#{node['rails']['zcache']['version']}/#{node['rails']['zcache']['file']}.zip"

default['rails']['zcache']['path'] = '/usr/local/zcache'
default['rails']['zcache']['bin'] = "#{node['rails']['zcache']['path']}/bin/nheqminer"
