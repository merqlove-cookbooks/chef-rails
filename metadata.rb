name             'rails'
maintainer       'Alexander Merkulov'
maintainer_email 'sasha@merqlove.ru'
license          'Apache 2.0'
description      'Installs/Configures ruby/rails, php, databases and so on'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '1.0.0'

supports 'centos'
supports 'ubuntu'

# Base

depends 'chef-client', '~> 3.6.0'

depends 'build-essential', '~> 2.0.4'
depends 'yum-epel', '~> 0.4.0'
depends 'yum', '~> 3.2.2'
depends 'iptables', '~> 0.13.2'
depends 'git', '~> 4.0.2'

depends 'rsync', '~> 0.8.4'
depends 'swap', '~> 0.3.6'
depends 'openssh', '~> 1.3.4'
depends 'openssl', '~> 2.0.0'
depends 'sudo', '~> 2.6.0'
depends 'fail2ban', '~> 2.1.2'

depends 'logrotate', '~> 1.6.0'
depends 'newrelic', '~> 1.0.6'

depends 'selinux', '~> 0.8.0'
depends 'vim', '~> 1.1.2'
depends 'curl', '~> 2.0.0'
depends 'packages', '~> 0.1.0'

depends 'database', '~> 2.2.0'
depends 'memcached', '~> 1.7.2'
# depends 'postfix', '~> 3.4.0'

# App

depends 'python', '~> 1.4.6'
depends 'yum-mysql-community', '~> 0.1.10'
depends 'composer', '~> 1.0.3'
depends 'php', '~> 1.4.6'
# depends 'apache2'
# depends 'java'
# depends 'tomcat'

# Other

depends 'apt'

# Personal repos

depends 'openssl-fips'
depends 'vsftpd'
depends 'duplicity_ng'
depends 'ssh_known_hosts'
depends 'nginx'
depends 'mongodb'
depends 'postgresql'
depends 'php-fpm'
depends 'msmtp'
depends 'vagrant-ohai'

# Official dev & 3rd side repos

depends 'mysql'
depends 'nodejs'
depends 'rbenv'
