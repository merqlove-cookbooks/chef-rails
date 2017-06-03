#
# Cookbook Name:: rails
# Provider:: waagent_disk
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

use_inline_resources

action :update do
  update_tmp(new_resource)
  ruby_block "update #{new_resource.config_path}" do
    block do
      file = Chef::Util::FileEdit.new(new_resource.config_path)
      update_swap(new_resource, file)
      update_format(new_resource, file)
      update_filesystem(new_resource, file)
      update_mount_point(new_resource, file)
      file.write_file
    end
  end

  new_resource.updated_by_last_action(true)
end

def update_tmp(new_resource)
  template_action = (new_resource.tmp && new_resource.format) ? :create : :delete

  template '/etc/profile.d/temp-folder.sh' do
    owner 'root'
    group 'root'
    mode 0o0644
    source 'etc/profile.d/temp-folder.sh.erb'
    action template_action
  end
end

def update_format(new_resource, file)
  waagent_no_format_regex = /ResourceDisk\.Format\=n/
  waagent_yes_format_regex = /ResourceDisk\.Format\=y/

  if new_resource.format
    file.search_file_replace_line(waagent_no_format_regex, "ResourceDisk.Format=y")
  else
    file.search_file_replace_line(waagent_yes_format_regex, "ResourceDisk.Format=n")
  end
end

def update_filesystem(new_resource, file)
  waagent_fs_regex = /ResourceDisk\.Filesystem\=.*/

  file.search_file_replace_line(waagent_fs_regex, "ResourceDisk.Filesystem=#{new_resource.filesystem}")
end

def update_mount_point(new_resource, file)
  waagent_mp_regex = /ResourceDisk\.MountPoint\=.*/

  file.search_file_replace_line(waagent_mp_regex, "ResourceDisk.MountPoint=#{new_resource.mount_point}")
end

def update_swap(new_resource, file)
  waagent_no_swap_regex = /ResourceDisk\.EnableSwap\=n/
  waagent_swap_regex = /ResourceDisk\.EnableSwap\=y/
  waagent_swap_size_regex = /ResourceDisk\.SwapSizeMB\=.*/

  if new_resource.enable_swap
    file.search_file_replace_line(waagent_no_swap_regex, "ResourceDisk.EnableSwap=y")
  else
    file.search_file_replace_line(waagent_swap_regex, 'ResourceDisk.EnableSwap=n')
  end
  file.search_file_replace_line(waagent_swap_size_regex, "ResourceDisk.SwapSizeMB=#{new_resource.swap_size}")
end
