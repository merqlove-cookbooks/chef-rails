#
# Cookbook Name:: rails
# Provider:: rbenv
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

use_inline_resources

action :create do
  install_ruby

  new_resource.updated_by_last_action(true)
end

def install_ruby
  node['rails']['rbenv']['versions'].each do |version, setup|
    rbenv_ruby version do
      ruby_version version
    end

    setup['gems'].each do |g|
      rbenv_gem g['name'] do
        ruby_version version
        version      g['version'] if g['version']
      end
    end
  end
end
