if node['rails']['nfs']['cachefilesd']
  package 'cachefilesd'

  file "/etc/default/cachefilesd" do
    content <<-EOS
RUN=yes
EOS
    action :create
    mode 0755
  end

  restart_cachefilesd = service 'cachefilesd' do
    action :nothing
  end

  ruby_block '/etc/cachefilesd.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/cachefilesd.conf')
      file.search_file_replace_line(/^dir.*/, "dir #{node['rails']['mnt']}")
      file.write_file
    end
    notifies :restart, restart_cachefilesd, :immediately
    only_if { File.exist?(node['rails']['mnt']) }
  end
end
