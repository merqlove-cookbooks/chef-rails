#
# Cookbook Name:: rails
# Resource:: backup
#
# Copyright (C) 2014 Alexander Merkulov
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

actions :create, :delete, :cleanup

default_action :create

attribute :name,     kind_of: String, name_attribute: true
attribute :cookbook, kind_of: String, default: 'rails' # Cookbook to find template

# Data Bag Ids
attribute :pass_key_id,     kind_of: String, default: node['rails']['duplicity']['pass_key_id']
attribute :storage_key_id,  kind_of: String, default: node['rails']['duplicity']['storage_key_id']

# Path
attribute :path,    kind_of: String, default: node['rails']['duplicity']['path']
attribute :target,  kind_of: String, default: node['rails']['duplicity']['target']

# S3 EU region
attribute :s3_eu,  kind_of: [TrueClass, FalseClass], default: node['rails']['duplicity']['s3']['eu']

# Create boto config?
attribute :boto_cfg,  kind_of: [TrueClass, FalseClass], default: node['rails']['duplicity']['boto_cfg']
attribute :main,      kind_of: [TrueClass, FalseClass], default: false

# Logging
attribute :log,      kind_of: [TrueClass, FalseClass], default: node['rails']['duplicity']['log']
attribute :logfile,  kind_of: String, default: node['rails']['duplicity']['log_file']

# Timing parameters
attribute :interval, kind_of: String, default: node['rails']['duplicity']['interval']
attribute :full_per, kind_of: String, default: node['rails']['duplicity']['full_per']

# Directory select
attribute :include,      kind_of: Array, default: node['rails']['duplicity']['include']
attribute :exclude,      kind_of: Array, default: node['rails']['duplicity']['exclude']
attribute :archive_dir,  kind_of: String, default: node['rails']['duplicity']['archive_dir']
attribute :temp_dir,     kind_of: String, default: node['rails']['duplicity']['temp_dir']

# Shell scripts that will be appended at the beginning/end of the cronjob
attribute :exec_pre,    kind_of: Array, default: node['rails']['duplicity']['exec_pre']
attribute :exec_before, kind_of: Array, default: node['rails']['duplicity']['exec_before']
attribute :exec_after,  kind_of: Array, default: node['rails']['duplicity']['exec_after']

# Size and speed
attribute :keep_full, kind_of: Integer, default: node['rails']['duplicity']['keep_full']
attribute :nice,      kind_of: Integer, default: nil
attribute :ionice,    kind_of: Integer, default: nil
