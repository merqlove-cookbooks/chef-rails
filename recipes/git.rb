#
# Cookbook Name:: rails
# Recipe:: git
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

# Add git user to node['rails']['git']['users']
# shell "/usr/bin/git-shell"

# Add git repos to node['rails']['git']['repositories']

# Setup repositories defined as node attributes
node['rails']['git']['repositories'].each do |name|  
  execute "git init --bare #{name}.git" do
    user "git"
    group "git"
    cwd "/home/git"
    creates "/home/git/#{name}.git"
  end
end

node['rails']['git']['users'].each do |user|
  directory "/home/git/#{user}" do
    user "git"
    group "git"
    mode "700"
  end
end
