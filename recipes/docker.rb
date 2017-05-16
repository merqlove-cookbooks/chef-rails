#
# Cookbook Name:: rails
# Recipe:: docker
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

if node['rails']['lvm_docker'] 
  docker_service 'default' do
    action [:create, :stop]
  end

  include_recipe "lvm::default"

  template '/etc/lvm/profile/docker-thinpool.profile' do
    owner    'root'
    group    'root'
    mode     0o0600
    source   'docker/docker-thinpool.profile.erb'
    variables(
      treshold: 80,
      percent: 20,
    )
    action :create
  end

  lvm_physical_volume '/dev/xvdf'

  lvm_volume_group 'docker' do
    physical_volumes ['/dev/xvdf']
    # wipe_signatures true

    logical_volume 'thinpool' do
      wipe_signatures true
      size            '95%VG'
    end

    logical_volume 'thinpoolmeta' do
      wipe_signatures true
      size            '1%VG'
    end

    # thin_pool "lv-thin-pool" do
    #   thin_volume "thinpool" do
    #     size '95%VG'
    #     filesystem  'ext4'
    #     mount_point location: '/var/thin01', options: 'noatime,nodiratime'
    #   end
    #   thin_volume "thin01" do
    #     size '1%VG'
    #     filesystem  'ext4'
    #     mount_point location: '/var/thin01', options: 'noatime,nodiratime'
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

  docker_service 'default' do
    action [:start]
  end
else
  docker_service 'default' do
    action [:create, :start]
  end
end
