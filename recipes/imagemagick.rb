#
# Cookbook Name:: rails
# Recipe:: imagemagick
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

imagemagick_package = 'imagemagick'
imagemagick_package = 'ImageMagick-last' if platform_family?('rhel')

package 'imagemagick' do
  package_name imagemagick_package
  action       :install
end
