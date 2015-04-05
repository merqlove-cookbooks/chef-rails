#
# Cookbook Name:: rails
# Attributes:: duplicity
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

# passwords data bag id
default['rails']['duplicity']['pass_key_id'] = 'main'
default['rails']['duplicity']['storage_key_id'] = node.default['rails']['duplicity']['pass_key_id']
default['rails']['duplicity']['boto_cfg'] = true
default['rails']['duplicity']['method'] = 's3+http' # possible 's3', "s3+http", 'gs', 'swift', 'ftp', 'ssh', ...

# path & log
default['rails']['duplicity']['path'] = '_system' # must be not empty!
default['rails']['duplicity']['log'] = false # Log or not
default['rails']['duplicity']['log_file'] = '/var/log/duplicity.log'

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
default['rails']['duplicity']['target'] = nil # must be not nil!
default['rails']['duplicity']['s3']['eu'] = false # eu buckets?
default['rails']['duplicity']['s3']['host'] = 's3.amazonaws.com' # optional

default['rails']['duplicity']['exec_pre'] = [] # ['if [ -f '/nobackup' ]; then exit 0; fi']
default['rails']['duplicity']['exec_before'] = [] # ['pg_dumpall -U postgres |bzip2 > /tmp/dump.sql.bz2']
default['rails']['duplicity']['exec_after'] = [] # ['touch /backup-sucessfull', 'echo yeeeh']

default['rails']['duplicity']['db'] = []
default['rails']['duplicity']['units'] = []
