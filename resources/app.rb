#
# Cookbook Name:: rails
# Resource:: app
#
# Copyright (C) 2013 Alexander Merkulov
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

actions        :create, :delete
default_action :create

attribute :name, kind_of: String, name_attribute: true

attribute :type,        kind_of: String, default: 'apps'
attribute :application, kind_of: Hash,   default: nil

# Cookbook to find template
attribute :cookbook, kind_of: String, default: 'rails'
