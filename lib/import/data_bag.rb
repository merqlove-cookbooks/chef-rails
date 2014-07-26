require 'chef'
require 'import/api'

module Rails
  module Import
    class DataBag < API

      attr_accessor :secret_file

      def download
        super

        bag = api.data_bag.find(resource)
        raw_json = bag.item.find(file).to_json

        raw_hash = Chef::JSONCompat.from_json(raw_json)
        bag_item = Chef::EncryptedDataBagItem.new raw_hash, secret
        FileUtils.mkdir_p(tmp_resource_dir("databags/#{@resource}"))
        IO.write tmp_resource_file('data_bags'), Chef::JSONCompat.to_json_pretty(bag_item.to_hash)
      end

      def decode
        Dir.glob("#{test_dir}/data_bags/**/*").each do |d|
          next if d == '.' || d == '..' || File.directory?(d)

          raw_hash = Chef::JSONCompat.from_json(raw_json)
          bag_item = Chef::EncryptedDataBagItem.new raw_hash, secret
          FileUtils.mkdir_p(tmp_resource_dir("databags/#{@resource}"))
          IO.write tmp_resource_file('data_bags'), Chef::JSONCompat.to_json_pretty(bag_item.to_hash)
        end
      end

      def encode

      end

      protected

      attr_writer :encrypt

      def auth
        auth = {
            server_url: "https://api.opscode.com/organizations/#{ENV['ORGNAME']}",
            client_name: "#{ENV['ORGNAME']}-validator",
            client_key: "#{ENV['HOME']}/.chef/#{ENV['ORGNAME']}-validator.pem"
        }
        secret = test ? test_secret_file : secret_file
        auth.merge(encrypted_data_bag_secret: secret) if secret
        @auth ||= auth
      end

      def file_save(tmp_file, file, dir)
        return unless tmp_file.include? 'data_bags'
        if encrypt
          raw_hash = Chef::JSONCompat.from_json IO.read File.expand_path(tmp_file)
          encrypted = Chef::EncryptedDataBagItem.encrypt_data_bag_item raw_hash, test_secret
          IO.write resource_file_path(dir, file), Chef::JSONCompat.to_json_pretty(encrypted)
        else
          FileUtils.cp(File.expand_path(tmp_file), resource_file_path(dir, file))
        end
      end

      def encrypt
        @encrypt ||= false
      end

      def secret
        @secret ||= Chef::EncryptedDataBagItem.load_secret secret_file
      end

      def test_secret
        @test_secret ||= Chef::EncryptedDataBagItem.load_secret test_secret_file
      end

      def resource_dir
        @resource_dir ||= "#{test_dir}/#{resource}"
      end

      def resource_path(name)
        "#{test_dir}/#{name}"
      end

      def test_secret_file
        @test_secret_file ||= "#{test_dir}/encrypted_data_bag_secret"
      end
    end
  end
end
