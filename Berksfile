#!/usr/bin/env ruby
#^syntax detection

def company_cookbook(name, version = '>= 0.0.0', options = {})
  cookbook(name, version, {
    git: "git@github.com:merqlove-cookbooks/chef-#{name}.git"
  }.merge(options))
end

source 'https://supermarket.chef.io'

group :java do
end

group :php do
  company_cookbook 'php-fpm'
end

group :nginx do
  # company_cookbook 'nginx'
end

group :ruby do
  cookbook 'rbenv', '~> 1.7.1', github: 'RiotGames/rbenv-cookbook'
  cookbook 'nodejs', '~> 2.4.0', github: 'redguide/nodejs', ref: 'v2.4.0'
end

group :mail do
  company_cookbook 'msmtp'
end

group :mongo do
  company_cookbook 'mongodb'
end
group :postgres do
  company_cookbook 'postgresql', '>= 0.0.0', branch: 'develop' #path: '../postgresql'
end

# company_cookbook 'duplicity_ng', '>= 0.0.0', branch: 'feature/fix_conditions_and_azure'

# base
group :production do
  %w(locale openssl-fips ssh_known_hosts timezone-ii vsftpd stunnel-wrapper nginx-wrapper).each do |name|
    company_cookbook name
  end
end

metadata

group :integration do
  cookbook 'minitest-handler', '~> 1.3.0'
  company_cookbook 'vagrant-ohai'
end
