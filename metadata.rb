name             'rails'
maintainer       'Alexander Merkulov'
maintainer_email 'sasha@merqlove.ru'
license          'Apache 2.0'
description      'Installs/Configures ruby/rails, php, databases and so on'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.4.0'

supports 'centos'
supports 'ubuntu'

depends 'openssl'
depends 'openssl-fips'
depends 'swap'
depends 'iptables'
depends 'ssh_known_hosts'
depends 'nginx'
depends 'rbenv'
depends 'mongodb'
depends 'postgresql'
depends 'mysql'
depends 'yum'
depends 'yum-epel'
depends 'apt'
depends 'database'
depends 'php'
depends 'php-fpm'
depends 'composer'
depends 'msmtp'
depends 'selinux'
depends 'nodejs'
depends 'python'
depends 'nodejs'
depends 'newrelic'
depends 'openssh'
depends 'vsftpd'
depends 'duplicity_ng'

# attribute 'hub/install_path',
#   display_name: 'Install path',
#   description: 'Base path where bin/hub will be installed',
#   type: 'string',
#   required: 'optional'

# attribute 'git/src_path',
#   display_name: 'Source path',
#   description: 'Path where hub git repo will be cloned',
#   type: 'string',
#   required: 'optional'
