#
# Cookbook Name:: rails
# Recipe:: rancher_server
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

directory node['rails']['rancher']['server']['db_dir'] do
  mode '0755'
end

docker_image node['rails']['rancher']['server']['image'] do
  tag node['rails']['rancher']['server']['version']
  action :pull
end

docker_container 'rancher' do
  repo node['rails']['rancher']['server']['image']
  tag node['rails']['rancher']['server']['version']
  port "#{node['rails']['rancher']['server']['port']}:8080"
  detach true
  restart_policy 'unless-stopped'
  volumes [ "#{ node['rails']['rancher']['server']['db_dir'] }:/var/lib/mysql" ]
  action :run
end
