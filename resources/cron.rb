#
# Cookbook Name:: rails
# Resource:: cron
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

actions :create, :delete, :init, :cleanup

default_action :create

attribute :name, name_attribute: true, kind_of: String
attribute :minute, kind_of: [String, Integer], default: '*'
attribute :hour, kind_of: [String, Integer], default: '*'
attribute :day, kind_of: [String, Integer], default: '*'
attribute :month, kind_of: [String, Integer], default: '*'
attribute :weekday, kind_of: [String, Integer], default: '*'
attribute :interval, kind_of: String, default: nil
attribute :user, kind_of: String, default: 'root'
attribute :command, kind_of: String, default: ''
attribute :mailto, kind_of: String, default: nil
attribute :path, kind_of: String, default: nil
attribute :home, kind_of: String, default: nil
attribute :shell, kind_of: String, default: nil
attribute :environment, kind_of: Hash, default: {}
