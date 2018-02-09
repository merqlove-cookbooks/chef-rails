#
# Cookbook Name:: rails
# Attributes:: freetds
#
# Copyright (C) 2018 Olivier Brisse, Alexander Merkulov
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

default['rails']['freetds']['install_method'] = 'package'
default['rails']['freetds']['version']        = '1.00.80'
default['rails']['freetds']['checksum']       = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'

if platform_family?('rhel') 
  default['rails']['freetds']['packages']       = %w(freetds freetds-devel)
else
  default['rails']['freetds']['packages']       = %w(freetds-bin freetds-dev)
end

default['rails']['freetds']['tds_version']    = '7.4'
default['rails']['freetds']['odbc']           = false
default['rails']['freetds']['text_size']      = 64_512
default['rails']['freetds']['client_charset'] = nil

case node['rails']['freetds']['install_method']
when 'package'
  default['rails']['freetds']['dir']          = '/etc/freetds'
when 'source'
  default['rails']['freetds']['dir']          = '/usr/local/etc'
end

default['rails']['freetds']['servers'] = []
