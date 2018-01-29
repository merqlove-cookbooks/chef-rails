#
# Cookbook Name:: rails
# Recipe:: iptables
#
# Copyright (C) 2013 Alexander Merkulov
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

::Chef::Recipe.send(:include, Rails::Helpers)

if node['rails']['firewall'].nil? || node['rails']['firewall'] == false
  firewall 'default' do
    action :disable
  end
elsif rhel7x? || ubuntu16x?
  node.default['firewall']['firewalld']['permanent'] = true

  firewall 'default'
  
  # execute 'firewall-cmd --zone=public --permanent --add-masquerade' do
  #   ignore_failure true
  # end

  [{ports: (node['rails']['ports'] || []), type: :tcp}, 
   {ports: (node['rails']['udp_ports'] || []), type: :udp}].each_with_index do |list|
    (list[:ports] || []).uniq.each do |port| 
      port_bind = port_cast(port)
      firewall_rule "#{port_name(port)}-#{list[:type]}" do
        port     port_bind
        protocol list[:type]
        command  :allow
      end
    end
  end
else
  include_recipe 'openssh::iptables'
  iptables_rule 'port_rails'
end
