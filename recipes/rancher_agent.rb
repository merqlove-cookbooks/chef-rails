#
# Cookbook Name:: rails
# Recipe:: rancher_agent
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

docker_image node['rails']['rancher']['agent']['image'] do
  tag node['rails']['rancher']['agent']['version']
  action :pull
end

docker_container 'rancher-agent' do
  image node['rails']['rancher']['agent']['image']
  tag node['rails']['rancher']['agent']['version']
  command "#{node['rails']['rancher']['server']['auth_url']}"
  volumes ['/var/run/docker.sock:/var/run/docker.sock', '/var/lib/rancher:/var/lib/rancher']
  container_name 'rancher-agent-init'
  env "CATTLE_AGENT_IP=\"#{ node['ipaddress'] }\""
  autoremove true
  privileged true
  not_if 'docker inspect rancher-agent'
end
