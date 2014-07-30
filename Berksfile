source 'https://api.berkshelf.com'

group :java do
  # cookbook 'java'
  # cookbook 'tomcat'
end

group :php do
  cookbook 'php', '~> 1.4.6'
  cookbook 'php-fpm', github: 'merqlove-cookbooks/chef-php-fpm'
  cookbook 'composer', '~> 1.0.3'
end

group :apache do
  # cookbook 'apache2'
end

group :nginx do
  cookbook 'nginx', github: 'merqlove-cookbooks/chef-nginx'
end

group :ruby do
  cookbook 'rbenv', '~> 1.7.1', github: 'RiotGames/rbenv-cookbook'
  cookbook 'nodejs', github: 'mdxp/nodejs-cookbook'
end

group :python do
  cookbook 'python', '~> 1.4.6'
end

group :mail do
  cookbook 'msmtp', github: 'merqlove-cookbooks/chef-msmtp'
  cookbook 'postfix', '~> 3.4.0'
end

group :mongo do
  cookbook 'mongodb', github: 'merqlove-cookbooks/chef-mongodb'
end
group :postgres do
  cookbook 'postgresql', github: 'merqlove-cookbooks/chef-postgresql'
end

group :mysql do
  cookbook 'mysql', github: 'LessonPlanet/mysql', ref: '4635b8c'
  cookbook 'yum-mysql-community', '~> 0.1.10'
end

# base
group :production do
  cookbook 'chef-client', '~> 3.6.0'
  cookbook 'duplicity_ng', github: 'merqlove-cookbooks/chef-duplicity_ng'

  cookbook 'database', github: 'opscode-cookbooks/database'
  cookbook 'memcached', '~> 1.7.2'

  cookbook 'build-essential', '~> 2.0.4'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'yum', '~> 3.2.2'
  cookbook 'iptables', '~> 0.13.2'
  cookbook 'git', '~> 4.0.2'

  cookbook 'locale', github: 'merqlove-cookbooks/chef-locale'
  cookbook 'rsync', '~> 0.8.4'
  cookbook 'swap', '~> 0.3.6'
  cookbook 'openssh', '~> 1.3.4'
  cookbook 'openssl-fips', github: 'merqlove-cookbooks/chef-openssl-fips'
  cookbook 'openssl', '~> 2.0.0'
  cookbook 'ssh_known_hosts', github: 'merqlove-cookbooks/chef-ssh_known_hosts'
  cookbook 'sudo', '~> 2.6.0'
  cookbook 'fail2ban', '~> 2.1.2'

  cookbook 'logrotate', '~> 1.6.0'
  cookbook 'timezone-ii', github: 'merqlove-cookbooks/chef-timezone-ii'
  cookbook 'vsftpd', github: 'merqlove-cookbooks/chef-vsftpd', branch: 'next'
  cookbook 'newrelic', '~> 1.0.6'

  cookbook 'selinux', '~> 0.8.0'
  cookbook 'vim', '~> 1.1.2'
  cookbook 'curl', '~> 2.0.0'
  cookbook 'packages', '~> 0.1.0'

  cookbook 'vagrant-ohai', github: 'merqlove-cookbooks/chef-vagrant-ohai'
end

metadata

group :integration do
  cookbook 'minitest-handler', '~> 1.3.0'
end


