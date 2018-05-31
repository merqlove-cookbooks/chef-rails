#
# Cookbook Name:: rails
# Provider:: mtproto
#
# Copyright (C) 2018 Alexander Merkulov
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
  mtproto_create(new_resource)

  new_resource.updated_by_last_action(true)
end

action :delete do
  mtproto_delete(new_resource)

  new_resource.updated_by_last_action(true)
end

def mtproto_create(new_resource)
  docker_image new_resource.image do
    tag new_resource.version
    action :pull
  end

  docker_container new_resource.name do
    image new_resource.image
    tag new_resource.version
    port "443:#{new_resource.port}"
    volumes ["proxy-config:#{new_resource.data_volume}"]
    env "SECRET=#{new_resource.secret}" if new_resource.secret
    env "SECRET_COUNT=#{new_resource.secret_count}" if new_resource.secret_count

    action :run
    not_if "docker inspect #{new_resource.name}"
  end

  debug_resource(new_resource,
                 %i[name image version restart data_volume port secret_count])
end

def mtproto_delete(new_resource)
  docker_container new_resource.name do
    action :delete
  end
end
