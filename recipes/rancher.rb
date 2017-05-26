::Chef::Recipe.send(:include, Rails::Helpers)

if node['rails']['rancher']
  data_bag = ::Chef::EncryptedDataBagItem.load(node['rails']['d']['rancher'], node['rancher_ng']['name'], load_secret) || {} # rubocop:disable Style/IndentationWidth

  if data_bag
    if data_bag['server']
      data_bag['server'].each do |k, v|
        node.default['rancher_ng']['server'][k] = v
      end
    end
    if data_bag['agent']
      data_bag['agent'].each do |k, v|
        node.default['rancher_ng']['agent'][k] = v
      end
    end
  end
end
