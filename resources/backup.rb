#
# Cookbook Name:: rails
# Resource:: backup
#
# Copyright (C) 2014 Alexander Merkulov
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

actions :create, :delete

default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :cookbook, :kind_of => [String, NilClass], :default => "rails" #Cookbook to find template

# Path
attribute :path,  :kind_of => [String, NilClass], :default => ''
attribute :target,  :kind_of => [String, NilClass], :default => nil

# S3 EU region
attribute :s3_eu,  :kind_of => [TrueClass, FalseClass, NilClass], :default => nil

# Logging
attribute :log,      :kind_of => [TrueClass, FalseClass, NilClass], :default => nil
attribute :logfile,  :kind_of => [String, NilClass], :default => nil

# Timing parameters
attribute :interval, :kind_of => [String, NilClass], :default => nil
attribute :full_per, :kind_of => [String, NilClass], :default => nil

# Directory select
attribute :include, :kind_of => [Array, NilClass], :default => nil
attribute :exclude, :kind_of => [Array, NilClass], :default => nil

# Shell scripts that will be appended at the beginning/end of the cronjob
attribute :exec_pre, :kind_of => [Array, NilClass], :default => nil
attribute :exec_before, :kind_of => [Array, NilClass], :default => nil
attribute :exec_after, :kind_of => [Array, NilClass], :default => nil

# Size and speed
attribute :keep_full, :kind_of => [Integer, NilClass], :default => nil
attribute :nice, :kind_of => [Integer, NilClass], :default => nil
attribute :ionice, :kind_of => [Integer, NilClass], :default => nil

def initialize(*args)
  super
  @action = :create
end
