
# Cookbook Name:: rails
# Resource:: waagent_disk
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

actions :update

default_action :update

attribute :name, name_attribute: true, kind_of: String
attribute :cookbook, kind_of: String, default: 'rails'

attribute :config_path, kind_of: String, default: '/etc/waagent.conf'
attribute :filesystem, kind_of: String, default: 'xfs'
attribute :format, kind_of: [TrueClass,FalseClass], default: false
attribute :mount_point, kind_of: String, default: (platform_family?('rhel') ? '/mnt/resource' : '/mnt')
attribute :enable_swap, kind_of: [TrueClass,FalseClass], default: false
attribute :swap_size, kind_of: Integer, default: 0
attribute :tmp, kind_of: [TrueClass,FalseClass], default: false
