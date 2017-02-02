#
# Cookbook Name:: rails
# Provider:: db_yml
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

use_inline_resources

action :create do
  database_name = new_resource.database_name || new_resource.name
  path = "#{new_resource.path}/db.#{new_resource.type}.#{database_name}.yml"

  template path do
    owner    new_resource.owner
    group    new_resource.group
    mode     00600
    source   new_resource.template
    cookbook new_resource.template ? new_resource.cookbook_name.to_s : new_resource.cookbook
    variables(
      host: new_resource.host,
      port: new_resource.port,
      pool: new_resource.pool,
      type: new_resource.type,
      socket: new_resource.socket,
      database: database_name,
      user: new_resource.database_user,
      password: new_resource.database_password,
    )
    action :create
  end

  new_resource.updated_by_last_action(true)
end
