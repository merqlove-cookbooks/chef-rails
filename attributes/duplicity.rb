#
# Cookbook Name:: rails
# Attributes:: duplicity
#
# Copyright (C) 2014 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# path & log
default['rails']['duplicity']['path'] = '/usr/local/bin/duplicity'
default['rails']['duplicity']['log'] = false # Log or not
default['rails']['duplicity']['log_file'] = "/var/log/duplicity.log"

# intervals
default['rails']['duplicity']['keep_full'] = 1
default['rails']['duplicity']['interval'] = 'daily'
default['rails']['duplicity']['full_per'] = '7D'

# directories
default['rails']['duplicity']['include'] = %w(/etc/ /root/ /var/log/)
default['rails']['duplicity']['exclude'] = %w()
default['rails']['duplicity']['archive_dir'] = '/tmp/duplicity-archive'
default['rails']['duplicity']['temp_dir'] = '/tmp/duplicity-tmp'

# cpu patch
default['rails']['duplicity']['nice'] = 10
default['rails']['duplicity']['ionice'] = 3

# Amazon S3, Google Cloud Storage defaults
default['rails']['duplicity']['bucket'] = nil # must set if we use buckets
default['rails']['duplicity']['s3']['eu'] = false # eu buckets?
default['rails']['duplicity']['s3']['host'] = 's3.amazonaws.com' # optional
