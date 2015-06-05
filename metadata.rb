name             'rails'
maintainer       'Alexander Merkulov'
maintainer_email 'sasha@merqlove.ru'
license          'Apache 2.0'
description      'Installs/Configures ruby/rails, php, databases and so on'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '1.2.7'

supports 'centos'
supports 'ubuntu'

# Base

depends 'chef-client', '~> 4.2.4'

depends 'build-essential', '~> 2.2.0'
depends 'yum-epel', '~> 0.6.0'
depends 'yum', '~> 3.5.3'
depends 'iptables', '~> 0.14.1'
depends 'git', '~> 4.1.0'

depends 'rsync', '~> 0.8.6'
depends 'swap', '~> 0.3.8'
depends 'openssh', '~> 1.3.4'
depends 'openssl', '>= 2.0.0'
depends 'sudo', '~> 2.7.1'
depends 'fail2ban', '~> 2.2.1'
depends 'cron', '~> 1.6.1'

depends 'logrotate', '~> 1.9.1'
depends 'newrelic', '~> 2.12.2'

depends 'selinux', '~> 0.9.0'
depends 'vim', '~> 1.1.2'
depends 'curl', '~> 2.0.1'
depends 'packages', '~> 0.4.0'

depends 'database', '~> 4.0.3'
depends 'memcached', '~> 1.7.2'
# depends 'postfix', '~> 3.4.0'

# App

depends 'python', '~> 1.4.6'
depends 'yum-mysql-community', '~> 0.1.14'
depends 'composer', '~> 2.0.0'
depends 'php', '~> 1.5.0'
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
depends 'duplicity_ng', '~> 1.2.2'
depends 'ssh_known_hosts'
depends 'nginx'
depends 'mongodb'
depends 'postgresql'
depends 'php-fpm'
depends 'msmtp'
depends 'vagrant-ohai'

# Official dev & 3rd side repos

depends 'nodejs'
depends 'rbenv'
