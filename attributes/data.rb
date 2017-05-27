#
# Cookbook Name:: rails
# Attributes:: data
#
# Copyright (C) 2015 Alexander Merkulov
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
default['rails']['drives'] = {}

default['rails']['d']['aws'] = 'aws'
default['rails']['d']['azure'] = 'azure'
default['rails']['d']['gs'] = 'gs'
default['rails']['d']['swift'] = 'swift'
default['rails']['d']['vcs_keys'] = 'vcs_keys'
default['rails']['d']['users'] = 'users'
default['rails']['d']['postgresql'] = 'postgresql'
default['rails']['d']['mysql'] = 'mysql'
default['rails']['d']['mongodb'] = 'mongodb'
default['rails']['d']['duplicity'] = 'duplicity'
default['rails']['d']['rancher'] = 'rancher'
