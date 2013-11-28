#
# Cookbook Name:: rails
# Resource:: nginx_vhost
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

actions :create, :delete, :enable, :disable

default_action :create

attribute :block, :kind_of => [String, Array, NilClass], :default => nil # Include additional code
attribute :name, :name_attribute => true, :kind_of => String
attribute :listen, :kind_of => [String, NilClass], :default => "80"  # Listening port, ip, etc.
attribute :server_name, :kind_of => [String, Array, NilClass], :default => nil # Server name if different then the name attribute.
attribute :path, :kind_of => [String, NilClass], :default => nil # Server root
attribute :default, :kind_of => [TrueClass, FalseClass], :default => false  # Default host
attribute :deferred, :kind_of => [TrueClass, FalseClass], :default => false  # Deffered host
attribute :disable_www, :kind_of => [TrueClass, FalseClass], :default => true #Redirect www to domain
attribute :access_log, :kind_of => [TrueClass, FalseClass], :default => false  # Access log
attribute :error_log, :kind_of => [TrueClass, FalseClass], :default => true  # Error log
attribute :php, :kind_of => [TrueClass, FalseClass], :default => false #PHP code
attribute :admin, :kind_of => [TrueClass, FalseClass], :default => false  # Access log
attribute :min, :kind_of => [TrueClass, FalseClass], :default => false #PHP code
attribute :locations, :kind_of => [Hash, NilClass], :default => {} # Locations to include.
attribute :rewrites, :kind_of => [Array, NilClass], :default => [] # Server rewrites
attribute :file_rewrites, :kind_of => [Array, NilClass], :default => [] # Server files rewrites
attribute :hidden, :kind_of => [Array, NilClass], :default => nil # Hidden paths
attribute :cookbook, :kind_of => [String, NilClass], :default => nil #Cookbook to find template
attribute :template, :kind_of => [String, NilClass], :default => nil # Template to use.
attribute :auto_enable_site, :kind_of => [TrueClass, FalseClass] , :default => true # Define if you want to link your newly created site conf from sites-availables to sites-enabled
attribute :ssl, :kind_of => [Hash, NilClass], :default => nil #Allow the creation of ssl cert files.
attribute :reload, :kind_of => [Symbol], :equal_to => [:delayed, :immediately], :default => :delayed # How soon should we restart nginx.

def initialize(*args)
  super
  @action = :create
end