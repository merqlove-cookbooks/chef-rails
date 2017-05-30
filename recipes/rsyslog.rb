include_recipe 'rsyslog::default'

package 'rsyslog-gnutls'

node['rails']['rsyslog']['configs'].each do |config, rows|
  data = rows.join("\n")
  template "/etc/rsyslog.d/#{config}" do
    source 'etc/rsyslog.d/rsyslog.erb'
    variables config: data
    notifies :restart, "service[rsyslog]", :delayed
  end
end 
