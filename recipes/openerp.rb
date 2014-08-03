#
# Cookbook Name:: rails
# Recipe:: openerp
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

apt_repository 'openerp' do
  uri          'http://nightly.openerp.com/7.0/nightly/deb'
  only_if { platform_family?('debian') }
end

yum_repository 'openerp' do
  baseurl          'http://nightly.openerp.com/7.0/nightly/rpm'
  only_if { platform_family?('rhel') }
end

package 'openerp'