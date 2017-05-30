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

(node['rails']['nfs']['exports'] || {}).each do |k, v|
  directory k do
    owner 'root'
    group 'root'
    mode 0o0755
  end

  nfs_export k do
    network v['network'] if v['network']
    anonuser v['anonuser'] if v['anonuser']
    anongroup v['anongroup'] if v['anongroup']
    writeable v['writeable'] || true
    sync v['sync'] || true
    options v['options'] || ['no_subtree_check']
  end
end
