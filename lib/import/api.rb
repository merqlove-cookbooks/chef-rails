require 'fileutils'
require 'ridley'
require 'json'

module Rails
  module Import # robocop:disable Style/Documentation
    class API
      PROJECT_ROOT = File.expand_path('../../..', __FILE__)

      attr_accessor :resource, :file
      attr_accessor :api

      def initialize(args = {})
        args.each_pair do |k, v|
          send("#{k}=", v)
        end
        self.api = Ridley.new(auth) if ridley
      end

      def download
        return unless api

        self.file ||= resource
      end

      def save_all # rubocop:disable Style/CyclomaticComplexity
        Dir.glob('tmp/**/*').each do |d|
          next if d == '.' || d == '..' || File.file?(d)
          dir = resource_path(d.sub('tmp/', ''))
          FileUtils.mkdir_p(dir)
          Dir.glob("#{d}/*").each do |i|
            next if i == '.' || i == '..' || File.directory?(i)
            file = i.sub(d, '')
            file_save(i, file, dir)
          end
        end
        # clean
      end

      def clean
        Dir.glob('tmp/*').each do |d|
          next if d == '.' || d == '..'
          FileUtils.remove_dir(d, true)
        end
      end

      protected

      attr_writer :auth, :ridley
      attr_writer :resource_dir, :tmp_resource_dir
      attr_writer :resource_file, :tmp_resource_file
      attr_writer :test, :test_dir

      def auth
        @auth ||= {
          server_url: "https://api.opscode.com/organizations/#{ENV['ORGNAME']}",
          client_name: "#{ENV['ORGNAME']}-validator",
          client_key: "#{ENV['HOME']}/.chef/#{ENV['ORGNAME']}-validator.pem"
        }
      end

      def file_save(tmp_file, file, dir)
        FileUtils.cp(File.expand_path(tmp_file), resource_file_path(dir, file))
      end

      def ridley
        @ridley ||= false
      end

      def test
        @test ||= false
      end

      # path on resource type
      def tmp_resource_dir
        @tmp_resource_dir ||= "#{PROJECT_ROOT}"
      end

      # path on resource type
      def resource_dir
        @resource_dir ||= "#{test_dir}"
      end

      # path on resource type
      def resource_path(resource)
        "#{test_dir}/#{resource}"
      end

      def resource_file
        @resource_file ||= "#{resource_dir}/#{file}.json"
      end

      def resource_file_path(resource_dir, file)
        "#{resource_dir}/#{file}"
      end

      def tmp_resource_file
        @tmp_resource_file ||= "#{tmp_resource_dir}/#{file}.json"
      end

      def test_dir
        @test_dir ||= "#{PROJECT_ROOT}/test/integration/default"
      end
    end
  end
end
