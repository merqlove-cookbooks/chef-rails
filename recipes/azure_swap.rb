#
# Cookbook Name:: rails
# Definition:: azure_swap
#
# Copyright (C) 2017 Alexander Merkulov
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

if node['rails']['azure']['swap']
  waagent_file = "/etc/waagent.conf"
  waagent_no_swap_regex = /ResourceDisk\.EnableSwap\=n/
  waagent_swap_regex = /ResourceDisk\.EnableSwap\=y/
  waagent_no_swap_size_regex = /ResourceDisk\.SwapSizeMB\=0/

  ruby_block 'resource swap in waagent.conf' do
    block do
      file = Chef::Util::FileEdit.new(waagent_file)
      if node['rails']['swap']['enable']
        file.search_file_replace_line(waagent_no_swap_regex, 'ResourceDisk.EnableSwap=y')
      else
        file.search_file_replace_line(waagent_swap_regex, 'ResourceDisk.EnableSwap=n')
      end
      file.search_file_replace_line(waagent_no_swap_size_regex, "ResourceDisk.SwapSizeMB=#{node['rails']['swap']['size']}")
      file.write_file
    end
  end
end
