#
# Cookbook Name:: rails
# Resource:: ethereum
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

actions :create, :delete

default_action :create

attribute :name, name_attribute: true, kind_of: String
attribute :cookbook, kind_of: String, default: 'rails'
attribute :template, kind_of: String, default: 'ethminer.service.erb'

attribute :log_path, kind_of: String, default: "%h/.ethereum/geth.log"
attribute :wallet_address, kind_of: String, default: ""
attribute :pool_address, kind_of: String, default: ""

attribute :service_name, kind_of: String, default: "ethminer.service"
attribute :service_path, kind_of: String, default: "/etc/systemd/system"
