#
# Cookbook Name:: rails
# Recipe:: cleanup
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

node.default_attrs[:rails].delete(:databases) rescue nil
node.default_attrs[:msmtp].delete(:accounts) rescue nil

node.default_attrs[:mysql].delete(:server_debian_password) rescue nil
node.default_attrs[:mysql].delete(:server_root_password) rescue nil
node.default_attrs[:mysql].delete(:server_repl_password) rescue nil
node.normal_attrs[:mysql].delete(:server_debian_password) rescue nil
node.normal_attrs[:mysql].delete(:server_root_password) rescue nil
node.normal_attrs[:mysql].delete(:server_repl_password) rescue nil
node.override_attrs[:mysql].delete(:server_debian_password) rescue nil
node.override_attrs[:mysql].delete(:server_root_password) rescue nil
node.override_attrs[:mysql].delete(:server_repl_password) rescue nil

node.default_attrs[:postgresql][:password].delete(:postgres) rescue nil
node.normal_attrs[:postgresql][:password].delete(:postgres) rescue nil
node.override_attrs[:postgresql][:password].delete(:postgres) rescue nil

node.default_attrs[:rails].delete(:sites) rescue nil
node.default_attrs[:rails].delete(:apps) rescue nil
