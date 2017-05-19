#
# Cookbook Name:: rails
# Attributes:: rancher
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

# image and tag to use for rancher server image
default['rails']['rancher']['server']['image'] = 'rancher/server'
default['rails']['rancher']['server']['version'] = 'v1.6.0'

default['rails']['rancher']['server']['db_dir'] = '/var/lib/rmysql'

# IP or hostname of rancher server.  Agents use this to communicate to it.
# Leave as `nil` if you wish to use chef search
default['rails']['rancher']['server']['host'] = nil

# name of node running server.  This is used by search if 'host' is not set.
default['rails']['rancher']['server']['node_name'] = 'server'

# run rancher server with a data volume
default['rails']['rancher']['server']['volume_container'] = true

# Port to expose on host running the rancher server.
# in the form of 'port' or 'ip:port'
default['rails']['rancher']['server']['port'] = '8080'

# image and tag to use for rancher agent image
default['rails']['rancher']['agent']['image'] = 'rancher/agent'
default['rails']['rancher']['agent']['version'] = 'v1.2.2'
