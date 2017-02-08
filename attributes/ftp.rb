if node['rails']['vsftpd']
  node.default['rails']['ports'] << 21
  node.default['rails']['ports'] << node['vsftpd']['pasv_min_port']..node['vsftpd']['pasv_max_port']
end

