#
# Cookbook Name:: rails
# Recipe:: mtproto
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

rails_mtproto node['rails']['mtproto']['name'] do
  restart node['rails']['mtproto']['restart']
  data_volume node['rails']['mtproto']['data_volume']
  image node['rails']['mtproto']['image']
  version node['rails']['mtproto']['version']
  secret node['rails']['mtproto']['secret'] if node['rails']['mtproto']['secret']
  secret_count node['rails']['mtproto']['secret_count'] if node['rails']['mtproto']['secret_count']
  port node['rails']['mtproto']['port']

  action :create
end