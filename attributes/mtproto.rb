default['rails']['mtproto']['name'] = 'mtproto-proxy'
default['rails']['mtproto']['restart'] = 'always'
default['rails']['mtproto']['network_mode'] = 'docker-mtproto'
default['rails']['mtproto']['data_volume'] = '/data'
default['rails']['mtproto']['image'] = 'telegrammessenger/proxy'
default['rails']['mtproto']['version'] = '1.0'
default['rails']['mtproto']['port'] = '443'
default['rails']['mtproto']['secret'] = nil
default['rails']['mtproto']['secret_count'] = nil
