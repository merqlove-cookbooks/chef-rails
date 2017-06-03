if node['rails']['nfs']['cachefilesd']
  package 'cachefilesd'

  file "/etc/default/cachefilesd" do
    content <<-EOS
RUN=yes
DAEMON_OPTS=""
EOS
    action :create
    mode 0644
  end

  restart_cachefilesd = service 'cachefilesd' do
    action :nothing
  end

  dir = "#{node['rails']['mnt']}/fscache"

  directory dir do
    action :create
    only_if { File.exist?(node['rails']['mnt']) }
  end

  ruby_block '/etc/cachefilesd.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/cachefilesd.conf')
      file.search_file_replace_line(/^dir.*/, "dir #{dir}")
      file.write_file
    end
    notifies :restart, restart_cachefilesd, :immediately
    only_if { File.exist?(dir) }
  end
end
