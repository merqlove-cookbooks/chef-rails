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
  cookbook 'msmtp', '~> 0.4.0', path: '../msmtp' # github: 'merqlove/chef-msmtp'
  cookbook 'postfix'
end

group :mongo do
  cookbook 'mongodb', github: 'merqlove/chef-mongodb'
end
group :postgres do
  cookbook 'postgresql', github: 'merqlove/chef-postgresql'
end

group :mysql do
  cookbook 'mysql', github: 'LessonPlanet/mysql', ref: '4635b8c'
  cookbook 'yum-mysql-community'
end

# base
group :production do
  cookbook 'chef-client'
  cookbook 'duplicity_ng', github: 'merqlove/duplicity_ng', branch: 'centos59-support'

  cookbook 'database', github: 'opscode-cookbooks/database'
  cookbook 'memcached'

  cookbook 'build-essential'
  cookbook 'yum-corporate'
  cookbook 'yum-epel'
  cookbook 'yum'
  cookbook 'iptables'
  cookbook 'git'

  cookbook 'locale', path: '../locale'#github: 'merqlove/chef-locale'
  cookbook 'rsync'
  cookbook 'swap'
  cookbook 'openssh'
  cookbook 'openssl-fips', github: 'merqlove/chef-openssl-fips'
  cookbook 'openssl'
  cookbook 'ssh_known_hosts', '~> 1.1.2', github: 'merqlove/chef-ssh_known_hosts'
  cookbook 'sudo'
  cookbook 'fail2ban'

  cookbook 'logrotate'
  cookbook 'timezone-ii', path: '../timezone-ii'# github: 'merqlove/timezone-ii'
  cookbook 'vsftpd', github: 'merqlove/chef-vsftpd'
  cookbook 'newrelic'

  cookbook 'selinux'
  cookbook 'vim'
  cookbook 'curl'
  cookbook 'packages'

  cookbook 'vagrant-ohai', github: 'merqlove/cookbooks-vagrant-ohai'
end

metadata

group :integration do
  cookbook 'minitest-handler', '>= 1.3'
end


