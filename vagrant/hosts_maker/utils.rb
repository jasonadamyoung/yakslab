module VagrantHosts
  class MakerError < StandardError
  end

  class Utils

    def initialize(defaults:)
      @defaults = defaults
    end

    def box_name_string(base_name:, version_string:, count: nil)
      host_prefix = (count.nil?) ? base_name : sprintf("%s%02d",base_name,count)
      "#{host_prefix}-#{version_string.gsub('.','-')}#{@defaults['vagrant_domain']}"
    end

  end
end