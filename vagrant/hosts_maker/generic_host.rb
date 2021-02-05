require_relative "./utils.rb"
require_relative "./ip_allocator.rb"

module VagrantHosts
  class GenericHost

    def initialize(configuration_root:, values:, defaults:)
      @configuration_root = configuration_root
      @values = values
      @defaults = defaults
      @utils = Utils.new(defaults: defaults)
      @ip_allocator = IPAllocator.new(configuration_root: @configuration_root)
    end


    def host_and_group_configuration
      # standalone generic host
      box_settings = {}
      provisioner_settings = {}

      # box settings
      if @values["name"].nil?
        raise VagrantHosts::MakerError, "A host name for the generic single host is required."
      end

      box_settings["name"] = @values["name"]
      ["network", "memory", "cpu", "box"].each do |setting|
        box_settings[setting] = @values[setting] || @defaults[setting]
      end
      box_settings["ip_address"] = @ip_allocator.get_available_ip_address(host_name: box_settings["name"])

      # provisioner settings
      provisioner_settings = @values["provisioner_settings"] || {}

      # ansible settings
      ansible_settings = {}
      ansible_settings.merge!(@defaults["ansible"])
      merge_settings = @values["ansible_settings"] || {}
      ansible_settings.merge!(merge_settings)

      hosts = [{"box_settings" => box_settings, "provisioner_settings" => provisioner_settings, "ansible_settings" => ansible_settings}]
      groups = {'generic' => [box_settings['name']]}
      [hosts, groups]
    end
  end
end
