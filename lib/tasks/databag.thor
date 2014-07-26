PROJECT_ROOT = File.expand_path('../../..', __FILE__)
$LOAD_PATH.unshift "#{PROJECT_ROOT}/lib"

require 'import/data_bag'
require 'import/node'
require 'import/role'

module Rails
  class DataBag < Thor
    desc 'fetch', 'Edit encrypted databag item.'
    method_option :databag, type: :string, aliases: %w(-d), required: true
    method_option :item, type: :string, aliases: %w(-i), required: true
    method_option :secret_file, type: :string, default: "#{ENV['HOME']}/.chef/#{ENV['ORGNAME']}_secret", aliases: %w(-s)
    def fetch
      api = ::Rails::Import::DataBag.new secret_file: options['secret_file'],
                                       resource: options['databag'],
                                       file: options['item'],
                                       ridley: true,
                                       encrypt: true
      api.download
    end

    desc 'push', 'Encode and move DataBag temp files into test folder.'
    def push
      api = ::Rails::Import::DataBag.new encrypt: true
      api.save_all
    end

    desc 'clean', 'Clean fetched files.'
    def clean
      api = ::Rails::Import::DataBag.new
      api.clean
    end
  end

  class Role < Thor
    desc 'fetch', 'Edit encrypted databag item.'
    method_option :name, type: :string, aliases: %w(-n), required: true
    def fetch
      api = ::Rails::Import::Role.new resource: options['name'],
                                    ridley: true
      api.download
    end

    desc 'push', 'Move Role temp files into test folder.'
    def push
      api = ::Rails::Import::Role.new
      api.save_all
    end

    desc 'clean', 'Clean fetched files.'
    def clean
      api = ::Rails::Import::Role.new
      api.clean
    end
  end

  class Node < Thor
    desc 'fetch', 'Edit encrypted databag item.'
    method_option :name, type: :string, aliases: %w(-n), required: true
    def fetch
      api = ::Rails::Import::Node.new resource: options['name'],
                                    ridley: true
      api.download
    end

    desc 'push', 'Move Node temp files into test folder.'
    def push
      api = ::Rails::Import::Node.new
      api.save_all
    end

    desc 'clean', 'Clean fetched files.'
    def clean
      api = ::Rails::Import::Node.new
      api.clean
    end

  end
end
