name             'rails'
maintainer       'Alexander Merkulov'
maintainer_email 'sasha@merqlove.ru'
license          'Apache 2.0'
description      'Installs/Configures ruby/rails, php, databases and so on'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.2.8'

supports "centos"
supports "ubuntu"

depends "swap"
depends "iptables"
depends "nginx"
depends "rbenv"
depends "ssh_known_hosts"
depends "mongodb"
depends "postgresql"
depends "mysql"
depends "database"
depends "php"
depends "php-fpm"
depends "composer"
depends "msmtp"

# attribute "hub/install_path",
#   display_name: "Install path",
#   description: "Base path where bin/hub will be installed",
#   type: "string",
#   required: "optional"

# attribute "git/src_path",
#   display_name: "Source path",
#   description: "Path where hub git repo will be cloned",
#   type: "string",
#   required: "optional"