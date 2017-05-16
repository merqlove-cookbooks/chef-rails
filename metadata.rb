name             'rails'
maintainer       'Alexander Merkulov'
maintainer_email 'sasha@merqlove.ru'
license          'Apache 2.0'
description      'Installs/Configures ruby/rails, php, databases and so on'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       'https://github.com/merqlove-cookbooks/chef-rails/issues'
source_url       'https://github.com/merqlove-cookbooks/chef-rails'
version          '1.3.3'

supports 'centos'
supports 'ubuntu'

# Base

depends 'chef-client', '~> 4.6.0'

depends 'build-essential', '~> 2.2.0'
depends 'yum-epel', '~> 0.7.0'
depends 'yum', '~> 3.11.0'
depends 'git', '~> 5.0.0'
depends 'firewall', '~> 2.1'

depends 'rsync', '~> 0.8.6'
depends 'swap', '~> 0.3.8'
depends 'openssh', '~> 2.0.0'
depends 'openssl', '>= 2.0.0'
depends 'sudo', '~> 2.9.0'
depends 'fail2ban', '~> 2.3.0'
depends 'cron', '~> 1.7.0'
depends 'acme', '~> 2.0'

depends 'logrotate', '~> 1.9.1'
depends 'newrelic', '~> 2.19.0'

depends 'selinux', '~> 0.9.0'
depends 'vim', '~> 2.0.1'
depends 'curl', '~> 2.0.1'
depends 'packages', '~> 1.0.0'

depends 'database', '~> 4.0.3'
depends 'memcached', '~> 2.1.0'
depends 'mongodb3-objects', '~> 0.4.5'
# depends 'postfix', '~> 3.4.0'

# App

depends 'python', '~> 1.4.6'
depends 'yum-mysql-community', '~> 0.1.14'
depends 'composer', '~> 2.3.0'
depends 'php', '~> 1.9.0'
depends 'mysql', '~> 6.0.17'
depends 'mysql2_chef_gem', '~> 1.0.1'
# depends 'apache2'
# depends 'java'
# depends 'tomcat'

# Other

depends 'apt'

# Personal repos

depends 'openssl-fips'
depends 'vsftpd'
depends 'docker', '~> 2.0'
depends 'lvm', '~> 4.1.0'
depends 'stunnel-wrapper'
depends 'iptables-wrapper'
depends 'duplicity_ng', '~> 1.2.2'
depends 'ssh_known_hosts'
depends 'nginx-wrapper'
depends 'postgresql-wrapper'
depends 'php-fpm-wrapper'
depends 'msmtp'
depends 'vagrant-ohai'

# Official dev & 3rd side repos

depends 'nodejs'
depends 'rbenv'
