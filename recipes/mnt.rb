template '/etc/profile.d/temp-folder.sh' do
  source 'etc/profile.d/temp-folder.sh.erb'
  only_if { node['rails']['mnt'] && true }
end
