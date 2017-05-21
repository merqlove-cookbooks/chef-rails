#
# Cookbook Name:: rails
# Provider:: docker
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

::Chef::Provider.send(:include, Rails::Helpers)

action :create do
  if rhel?
    run_context.include_recipe('chef-yum-docker::default')
  else
    run_context.include_recipe('chef-apt-docker::default')
  end 

  if thin_enabled?
    lvm(new_resource)
  else
    docker_create(new_resource)
  end

  new_resource.updated_by_last_action(true)
end

action :delete do
  docker_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def lvm(new_resource)
  run_context.include_recipe 'lvm::default'

  return new_resource.updated_by_last_action(false) unless lvm_disabled?
  
  docker_service new_resource.name do
    action [:create, :stop]
  end

  template '/etc/lvm/profile/docker-thinpool.profile' do
    owner    'root'
    group    'root'
    mode     0o0644
    source   'docker/docker-thinpool.profile.erb'
    variables(
      treshold: 80,
      percent: 20,
    )
    action :create
  end

  lvm_physical_volume node['rails']['docker_volume']

  lvm_volume_group 'docker' do
    physical_volumes [node['rails']['docker_volume']]
    # wipe_signatures true

    logical_volume 'thinpool' do
      wipe_signatures true
      size            '95%VG'
    end
    
    logical_volume 'thinpoolmeta' do
      wipe_signatures true
      size            '1%VG'
    end

    # thin_pool "thinpool" do
    #   size '95%VG'
    #   thin_volume "thinpool" do
    #     filesystem 'xfs'
    #     filesystem_params '--zero n -c 512K --poolmetadatasize 1%VG --metadataprofile docker-thinpool'       
    #   end
    # end
  end

  execute 'lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta'

  execute  'lvchange --metadataprofile docker-thinpool docker/thinpool'

  # verified the lv is monitored
  execute 'lvs -o+seg_monitor'

  template '/etc/docker/daemon.json' do
    owner    'root'
    group    'root'
    mode     0o0600
    source   'docker/daemon.json.erb'
    variables(
      driver: "devicemapper",
      driver_path: '/dev/mapper/docker-thinpool',
      driver_removal: true,
    )
    action :create
  end

  # if docker was previously started, clear your graph driver directory
  execute 'rm -rf /var/lib/docker/*'

  docker_create(new_resource)
end

def thin_enabled?
  thin_volume? && no_thin_volume?
end

def thin_volume?
  node['rails']['docker_volume'] && node['rails']['lvm_docker']
end

def no_thin_volume?
  `lvs -o+seg_monitor | grep 'thinpool.*monitored'`.strip.empty?
end

def docker_create(new_resource)
  docker_service new_resource.name do
    action [:create, :start]
    install_method 'package'
    version new_resource.version if new_resource.version
    checksum new_resource.checksum if checksum new_resource.checksum
    storage_driver node['rails']['docker_driver'] if node['rails']['docker_driver']
  end
end

def docker_delete(new_resource)
  docker_service new_resource.name do
    action [:stop, :delete]
  end
end
