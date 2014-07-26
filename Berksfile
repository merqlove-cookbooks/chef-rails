source 'https://api.berkshelf.com'

group :java do
  # cookbook 'java'
  # cookbook 'tomcat'
end

group :php do
  cookbook 'php', github: 'opscode-cookbooks/php'
  cookbook 'php-fpm', github: 'merqlove/chef-php-fpm'
  cookbook 'composer'
end

group :apache do
  # cookbook 'apache2'
end

group :nginx do
  cookbook 'nginx', '2.7.4', github: 'merqlove/chef-nginx'
end

group :ruby do
  cookbook 'rbenv', '~> 1.7.1', github: 'RiotGames/rbenv-cookbook'
  cookbook 'nodejs', github: 'mdxp/nodejs-cookbook'
end

group :python do
  cookbook 'python'
end

group :mail do
  cookbook 'msmtp', '~> 0.4.0', github: 'merqlove/chef-msmtp'
  cookbook 'postfix'
end

group :mongo do
  cookbook 'mongodb', github: 'merqlove/chef-mongodb'
end
group :postgres do
  cookbook 'postgresql', github: 'merqlove/chef-postgresql'
end

group :mysql do
  cookbook 'mysql', github: 'opscode-cookbooks/mysql'
  cookbook 'yum-mysql-community'
end

# base
group :production do
  cookbook 'chef-client'
  cookbook 'duplicity_ng', github: 'merqlove/duplicity_ng'

  cookbook 'database', github: 'opscode-cookbooks/database'
  cookbook 'memcached'

  cookbook 'build-essential'
  cookbook 'yum-corporate'
  cookbook 'yum-epel'
  cookbook 'yum-remi', github: 'aiming-cookbooks/yum-remi'
  cookbook 'iptables'
  cookbook 'git'

  cookbook 'locale', github: 'merqlove/chef-locale'
  cookbook 'rsync'
  cookbook 'swap'
  cookbook 'openssh'
  cookbook 'openssl-fips', github: 'merqlove/chef-openssl-fips'
  cookbook 'ssh_known_hosts', '~> 1.1.2', github: 'merqlove/chef-ssh_known_hosts'
  cookbook 'sudo'
  cookbook 'fail2ban'

  cookbook 'logrotate'
  cookbook 'timezone-ii', github: 'L2G/timezone-ii'
  cookbook 'vsftpd', github: 'merqlove/chef-vsftpd'
  cookbook 'newrelic'

  cookbook 'rails', '~> 0.3.1', github: 'merqlove/chef-rails'

  cookbook 'selinux'
  cookbook 'vim'
  cookbook 'curl'
  cookbook 'packages'

  cookbook 'vagrant-ohai', github: 'merqlove/cookbooks-vagrant-ohai'
end

metadata

group :integration do
  cookbook 'minitest-handler', github: 'btm/minitest-handler-cookbook', ref: 'f51f50925049cfcb856d527123fda90961d739e5'
end


