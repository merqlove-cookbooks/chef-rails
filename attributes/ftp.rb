if node['vsftpd']['enabled']
  node.default['rails']['ports'] << 21
  node.default['rails']['ports'] << {min: node['vsftpd']['config']['pasv_min_port'], max: node['vsftpd']['config']['pasv_max_port']}
end

