#
# Cookbook Name:: rails
# Recipe:: apps
#
# Copyright (C) 2013 Alexander Merkulov
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node['rails']['apps']
  users = node['rails']['apps'].map do |a|
    directory "#{node['rails']['base_path']}/#{a["name"]}" do
      owner a["user"]
      group a["user"]
      mode "0755"
      action :create
      recursive true
    end

    #set ruby
    unless a["rbenv"]["version"].include? node['rails']['rbenv']['version']
      rbenv_ruby "#{a["rbenv"]["version"]}" do
        ruby_version "#{a["rbenv"]["version"]}"
      end      
    end

    #add gems
    a["rbenv"]["gems"].each do |g|
      rbenv_gem "#{g}" do
        ruby_version "#{a["rbenv"]["version"]}"
      end
    end
  end
end