module Rails
  # include Chef::
  # Helpers for cookbook
  module Helpers
    def load_secret
      ::Chef::EncryptedDataBagItem.load_secret(node['rails']['secrets']['default']) if File.exist?(node['rails']['secrets']['default'])
    end

    def hash_in_array?(other_array, value)
      other_array.each { |h| return true if h.is_a?(Hash) && h.value?(value) }
      false
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
    # Determine if the current node using new RHEL.
    #
    # @return [Boolean]
    #
    def rhel7x?
      platform_family?('rhel') && node['platform_version'].to_f >= 7
    end
    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def rhel?
      platform_family?('rhel')
    end
    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def debian?
      platform_family?('debian')
    end
    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def php?
      ::FileTest.exist?('/usr/bin/php')
    end
    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def ubuntu12x?
      platform_family?('debian') && node['platform_version'][/^12/]
    end
    #
    # Determine if the current node using old RHEL.
    #
    # @return [Boolean]
    #
    def ubuntu14x?
      platform_family?('debian') && node['platform_version'][/^14/]
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
      if tv.is_a?(Hash) && v.is_a?(Hash)
        self[k] = tv.deep_merge(v, &block)
      else
        self[k] = block && tv ? block.call(k, tv, v) : v
      end
    end
    self
  end
end
