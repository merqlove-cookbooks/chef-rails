#!/usr/bin/env ruby
#^syntax detection

def company_cookbook(name, version = '>= 0.0.0', options = {})
  cookbook(name, version, {
    git: "git@github.com:merqlove-cookbooks/chef-#{name}.git"
  }.merge(options))
end

source 'https://api.berkshelf.com'

group :java do

end

group :php do
  company_cookbook 'php-fpm'
end

group :nginx do
  company_cookbook 'nginx'
end

group :ruby do
  cookbook 'rbenv', '~> 1.7.1', github: 'RiotGames/rbenv-cookbook'
  cookbook 'nodejs', github: 'mdxp/nodejs-cookbook'
end

group :mail do
  company_cookbook 'msmtp'
end

group :mongo do
  company_cookbook 'mongodb'
end
group :postgres do
  company_cookbook 'postgresql'
end

group :mysql do
  cookbook 'mysql', github: 'LessonPlanet/mysql', ref: '4635b8c'
end

# base
group :production do
  %w(duplicity_ng locale openssl-fips ssh_known_hosts timezone-ii vsftpd).each do |name|
    company_cookbook name
  end
end

metadata

group :integration do
  cookbook 'minitest-handler', '~> 1.3.0'
  company_cookbook 'vagrant-ohai'
end
