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
  opts = {no_lvm: true}

  include_recipe "lvm::default"

  ruby_block 'check_lvm' do
    block do
      unless `lvs -o+seg_monitor | grep 'thinpool.*monitored'`.strip.empty?
        opts[:no_lvm] = false
      end
    end    
    action :run
  end

  log 'lvm state' do
    message opts.to_s
    level :info
  end

  if opts[:no_lvm] && node['rails']['docker_volume']
    docker_service 'default' do
      action [:create, :stop]
    end

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
  end

  docker_service 'default' do
    action [:create, :start]
  end
else
  docker_service 'default' do
    action [:create, :start]
    storage_driver node['rails']['docker_driver'] if node['rails']['docker_driver']
  end
end
