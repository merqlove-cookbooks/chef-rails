require 'import/api'

module Rails
  module Import
    class Node < API

      def download
        super

        raw_json = JSON.pretty_generate(api.node.find(resource))
        FileUtils.mkdir_p(tmp_resource_dir('nodes'))
        IO.write tmp_resource_file, raw_json
      end

      protected

      def file_save(tmp_file, file, dir)
        return unless tmp_file.include? 'nodes'
        super
      end
    end
  end
end