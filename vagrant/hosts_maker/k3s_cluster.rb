require_relative "./utils.rb"
require_relative "./ip_allocator.rb"

module VagrantHosts
  class K3sCluster
    K3S_VERSIONS_CACHE = "cached_k3s_release_info.yml"
    K3S_ANSIBLE_PLAYBOOK   = "provisioning/k3s.yml"

    def initialize(configuration_root:, values:, defaults:)
      @configuration_root = configuration_root
      @k3s_version_cache = File.join(@configuration_root,K3S_VERSIONS_CACHE)
      @values = values
      @defaults = defaults
      @utils = Utils.new(defaults: defaults)
      @ip_allocator = IPAllocator.new(configuration_root: @configuration_root)
    end

    def host_and_group_configuration
      # three hosts - 1 server, 2 agents
      cluster_hosts = []
      server_host = {"box_settings" => {}, "provisioner_settings" => {}}

      k3s_cluster_values = @values.is_a?(Hash) ? @values : {"version" => @values.to_s}
      (service_version,k3s_checksum) = get_k3s_version(version: k3s_cluster_values["version"])

      # server settings
      server_host["box_settings"]["name"] = k3s_cluster_values["server_name"] || @utils.box_name_string(base_name: 'k3s-server', version_string: k3s_cluster_values["version"])

      ["network", "memory", "cpu", "box"].each do |setting|
        server_host["box_settings"][setting] = k3s_cluster_values["server_#{setting}"] || @defaults[setting]
      end
      server_host["box_settings"]["ip_address"] = @ip_allocator.get_available_ip_address(host_name: server_host["box_settings"]["name"])

      # provisioner settings
      server_host["provisioner_settings"]['k3s_server_ip'] = server_host["box_settings"]["ip_address"]
      server_host["provisioner_settings"]['k3s_version']   = service_version
      server_host["provisioner_settings"]['k3s_checksum']  = k3s_checksum
      server_host["provisioner_settings"]['k3s_role']      = "server"

      merge_settings = k3s_cluster_values["server_provisioner_settings"] || {}
      server_host["provisioner_settings"].merge!(merge_settings)


      server_host["ansible_settings"] = {}
      server_host["ansible_settings"].merge!(@defaults["ansible"])
      server_host["ansible_settings"]['playbook'] = K3S_ANSIBLE_PLAYBOOK
      merge_settings = k3s_cluster_values["ansible_settings"] || {}
      server_host["ansible_settings"].merge!(merge_settings)

      cluster_hosts << server_host

      (1..2).each do |agent_count|
        box_settings = {}
        provisioner_settings = {}

        agent_name = k3s_cluster_values["agent_name"] || "k3s-agent"
        box_settings["name"] = @utils.box_name_string(base_name: agent_name, version_string: k3s_cluster_values["version"], count: agent_count)
        ["network", "memory", "cpu", "box"].each do |setting|
          box_settings[setting] = k3s_cluster_values["agent_#{setting}"] || @defaults[setting]
        end
        box_settings["ip_address"] = @ip_allocator.get_available_ip_address(host_name: box_settings["name"])

        # provisioner settings
        provisioner_settings['k3s_server_ip'] = server_host["box_settings"]["ip_address"]
        provisioner_settings['k3s_agent_ip']  = box_settings["ip_address"]
        provisioner_settings['k3s_version']   = service_version
        provisioner_settings['k3s_checksum']  = k3s_checksum
        provisioner_settings['k3s_role']      = 'agent'

        merge_settings = k3s_cluster_values["agent_provisioner_settings"] || {}
        provisioner_settings.merge!(merge_settings)

        ansible_settings = {}
        ansible_settings.merge!(@defaults["ansible"])
        ansible_settings['playbook'] = K3S_ANSIBLE_PLAYBOOK
        merge_settings = k3s_cluster_values["ansible_settings"] || {}
        ansible_settings.merge!(merge_settings)

        cluster_hosts << {"box_settings" => box_settings, "provisioner_settings" => provisioner_settings, "ansible_settings" => ansible_settings}
      end

      # make groups
      groups = {'k3s' => []}
      cluster_hosts.each do |host|
        groups['k3s'] << host["box_settings"]["name"]
      end

      [cluster_hosts, groups]
    end

    def get_k3s_version(version:)
      if(!File.exists?(@k3s_version_cache))
        raise VagrantHosts::MakerError, "Please create the K3s version cache file: #{@k3s_version_cache}"
      end
      k3s_versions =  YAML.load_file(@k3s_version_cache)

      if(version == 'latest')
        k3s_version = k3s_versions["latest"]
        [k3s_version["name"],k3s_version["checksum"]]
      else
        version_number = Gem::Version.new(version)
        (major,minor,patch) = version_number.segments
        check_key = "#{major}.#{minor}"
        if(!k3s_versions.keys.include?(check_key))
          raise VagrantHosts::MakerError, "Invalid kubernetes version specified in #{version}"
        end

        if(patch.nil?)
          k3s_version = k3s_versions[check_key]["latest"]
          [k3s_version["name"],k3s_version["checksum"]]
        else
          specific_version = "#{major}.#{minor}.#{patch}"
          if(!k3s_versions[check_key].keys.include?(specific_version))
            raise VagrantHosts::MakerError, "The specified k3s version: #{version} does not exist"
          end
          k3s_version = k3s_versions[check_key][specific_version]
          [k3s_version["name"],k3s_version["checksum"]]
        end
      end
    end
  end
end