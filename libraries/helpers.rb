module DockerCookbook
  module DockerHelpers
    module Service
      def installed_docker_version
        return nil unless ::File.exist?(docker_bin)
        o = shell_out("#{docker_bin} --version")
        s = o.stdout.split[2]
        s.chomp(',') if s
      end

      def docker_major_version
        ray = installed_docker_version
        return if ray.nil?
        ray = ray.split('.')
        ray.pop
        ray.push.join('.')
      end
    end
  end
end

module Rails
  # include Chef::
  # Helpers for cookbook
  module Helpers
    def print_json(new_resource, opts)
      opts.reduce("\n") do |acc, key|
        acc << "#{key}: #{new_resource.send(key)}\n"
        acc
      end
    end

    def debug_resource(new_resource, opts = [])
      log print_json(new_resource, opts)
    end

    def load_secret
      ::Chef::EncryptedDataBagItem.load_secret(node['rails']['secrets']['default']) if File.exist?(node['rails']['secrets']['default'])
    end

    def hash_in_array?(other_array, value)
      other_array.each { |h| return true if h.is_a?(Hash) && h.value?(value) }
      false
    end

    def azure?
      node['cloud_v2']['provider'] == 'azure'
    end

    def rails_fqdn
      node['rails']['fqdn'] ? node['fqdn'] : node.name
    end

    def vagrant?
      node.role?('vagrant') || node.role?('kitchen')
    end

    def database_type_exist?(type)
      node['rails']['databases'] && node['rails']['databases'].include?(type)
    end

    def php_fpm?
      node['php-fpm'] && node['php-fpm']['pools'].count > 1
    end

    def port_name(port)
      if port.is_a?(Hash)
        port.to_a.map {|p| p.join('_') }.join('_')
      elsif port.is_a?(Array)
        port.join('_')
      else
        port
      end
    end

    def port_cast(port)
      if port.is_a?(String)
        port.to_i
      elsif port.is_a?(Hash)
        port[:min]..port[:max]
      else
        port
      end
    end

    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def rhel5x?
      major_version = node['platform_version'].split('.').first.to_i
      platform_family?('rhel') && major_version < 6
    end

    #
    # Determine if the current node using 6.x RHEL.
    #
    # @return [Boolean]
    #
    def rhel6x?
      major_version = node['platform_version'].split('.').first.to_i
      platform_family?('rhel') && major_version >= 6 && major_version < 7
    end

    #
    # Determine if the current node using new RHEL.
    #
    # @return [Boolean]
    #
    def rhel7x?
      platform_family?('rhel') && node['platform_version'].to_f >= 7
    end

    #
    # Determine if the current node using RHEL.
    #
    # @return [Boolean]
    #
    def rhel?
      platform_family?('rhel')
    end

    #
    # Determine if the current node using debian.
    #
    # @return [Boolean]
    #
    def debian?
      platform_family?('debian')
    end

    #
    # Determine if the current node has php installed.
    #
    # @return [Boolean]
    #
    def php?
      ::FileTest.exist?('/usr/bin/php')
    end

    #
    # Determine if the current node using Ubuntu 12.
    #
    # @return [Boolean]
    #
    def ubuntu12x?
      platform_family?('debian') && node['platform_version'][/^12/]
    end

    #
    # Determine if the current node using Ubuntu 14.
    #
    # @return [Boolean]
    #
    def ubuntu14x?
      platform_family?('debian') && node['platform_version'][/^14/]
    end

    #
    # Determine if the current node using Ubuntu 16.
    #
    # @return [Boolean]
    #
    def ubuntu16x?
      platform_family?('debian') && node['platform_version'][/^16/]
    end

    def php_exist?
      node['rails']['php']['install']
    end
  end
end

# Deep merge from RoR
class Hash
  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |k, v|
      tv = self[k]
      self[k] = if tv.is_a?(Hash) && v.is_a?(Hash)
                  tv.deep_merge(v, &block)
                else
                  block && tv ? yield(k, tv, v) : v
                end
    end
    self
  end
end
