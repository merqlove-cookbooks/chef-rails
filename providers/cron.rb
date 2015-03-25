#
# Cookbook Name:: rails
# Provider:: cron
#
# Copyright (C) 2015 Alexander Merkulov
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

action :init do
  node['rails']['crons'].each do |cron|
    cron_d "cron-#{cron.name}" do
      predefined_value cron[:interval]
      minute  cron[:minute]
      hour    cron[:hour]
      day     cron[:day]
      month   cron[:month]
      weekday cron[:weekday]
      command cron[:command]
      user    cron[:user]
      mailto  cron[:mailto]
      path    cron[:path]
      home    cron[:home]
      shell   cron[:shell]

      action :create
    end
  end

  new_resource.updated_by_last_action(true)
end

action :cleanup do
  ::Dir[ ::File.join('/etc/cron.d/cron-*') ].each do |c|
    next if cron_active?(c)

    ::File.delete(c)
  end
end

action :create do
  node.default['rails']['crons'] << {
    name: new_resource.name,
    interval: new_resource.interval,
    minute: new_resource.minute,
    hour: new_resource.hour,
    day: new_resource.day,
    month: new_resource.month,
    weekday: new_resource.weekday,
    command: new_resource.command,
    user: new_resource.user,
    mailto: new_resource.mailto,
    path: new_resource.path,
    home: new_resource.home,
    shell: new_resource.shell
  }

  new_resource.updated_by_last_action(true)
end

action :delete do
  cron_d new_resource.name do
    action :delete
  end

  new_resource.updated_by_last_action(true)
end

def cron_active?(name)
  node['rails']['crons'].each do |cron|
    return true if name.include?(cron[:name])
  end
  false
end
