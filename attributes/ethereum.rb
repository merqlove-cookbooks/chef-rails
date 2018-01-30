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

defaults['rails']['ethereum'] = {
  'name' => 'ether1',
  'wallet' => ''
}
defaults['rails']['ethereum']['source']['version'] = '1.7.3'
defaults['rails']['ethereum']['source']['checksum'] = '64a9f19eeccb3c094e7f9d2d936cd2d48aee3a2cc03148b980e0462c7579a73a',
defaults['rails']['ethereum']['source']['url'] = "https://github.com/ethereum/go-ethereum/archive/v#{node['rails']['ethereum']['source']['version']}.tgz"
