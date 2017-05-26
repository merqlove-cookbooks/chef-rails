::Chef::Recipe.send(:include, Rails::Helpers)

if node['rails']['rancher']
  data_bag = ::Chef::EncryptedDataBagItem.load(node['rails']['d']['rancher'], node['rancher_ng']['server']['name'], load_secret) || {} # rubocop:disable Style/IndentationWidth

  if data_bag
    if data_bag['server']
      log 'Rancher server:'
      data_bag['server'].each do |k, v|
        node.default['rancher_ng']['server'][k.to_s] = v
        log "#{k}: #{v}"
      end
    end
    if data_bag['agent']
      log 'Rancher agent:'
      data_bag['agent'].each do |k, v|
        node.default['rancher_ng']['agent'][k.to_s] = v
        log "#{k}: #{v}"
      end
    end
  end
end
