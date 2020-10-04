class VagrantHostsMaker

  GITLAB_VERSIONS_CACHE = ".vagrant_gitlab_versions.yml"
  HOST_FILE = "vagrant-hosts.yml"
  VMWARE_DHCP_CONFIG = "/Library/Preferences/VMware\ Fusion/vmnet8/dhcpd.conf"
  VAGRANT_HOSTIP_CACHE = ".vagrant_hostip_cache.yml"


  def initialize
    @host_file_data = YAML.load_file(HOST_FILE)
    @defaults = @host_file_data["defaults"]
  end

  def get_host_group(group: 'default')
    returnhosts = []
    group = @defaults["group"] if (group == "default")
    if(!@host_file_data[group])
      raise VagrantError, "The specified group: #{group} was not found in #{HOST_FILE}"
    end

    @host_file_data[group].each do |hosts_entry|
      returnhosts += process_hosts_entry(hosts_entry: hosts_entry)
    end
    returnhosts
  end

  def process_hosts_entry(hosts_entry:, other_hosts: [])
    (service,values) = hosts_entry.first

    # provisioner settings
    case service
    when 'gitlab'
      # standalone gitlab host
      gitlab_host(gitlab_values: values)
    when 'k3s_cluster'
      k3s_cluster(cluster_values: values)
    when 'single'
      single_host(host_values: values)
    end

  end

  def single_host(host_values:)
    # standalone generic host
    box_settings = {}
    provisioner_settings = {}

    # box settings
    if host_values["name"].nil?
      raise VagrantError, "A host name for the generic single host is required."
    end

    box_settings["name"] = host_values["name"]
    ["network", "memory", "cpu", "box"].each do |setting|
      box_settings[setting] = host_values[setting] || @defaults[setting]
    end
    box_settings["ip_address"] = get_available_ip_address(host_name: box_settings["name"])

    # provisioner settings
    provisioner_settings = host_values["provisioner_settings"] || {}
    [{"box_settings" => box_settings, "provisioner_settings" => provisioner_settings}]
  end

  def gitlab_host(gitlab_values:)
    # standalone gitlab host
    box_settings = {}
    provisioner_settings = {}

    # box settings
    host_values = gitlab_values.is_a?(String) ? {"version" => gitlab_values} : gitlab_values
    service_version = get_service_version(service: 'gitlab', version: host_values["version"])
    box_settings["name"] = host_values["name"] || box_name_string(service: 'gitlab', version: service_version)
    ["network", "memory", "cpu", "box"].each do |setting|
      box_settings[setting] = host_values[setting] || @defaults[setting]
    end
    box_settings["ip_address"] = get_available_ip_address(host_name: box_settings["name"])

    # provisioner settings
    provisioner_settings['gitlab_hostname']     = box_settings["name"]
    provisioner_settings['gitlab_external_url'] = "http://#{box_settings['name']}"
    provisioner_settings['gitlab_ip_address']   = box_settings["ip_address"]
    provisioner_settings['gitlab_version']      = service_version
    merge_settings = host_values["provisioner_settings"] || {}
    provisioner_settings.merge!(merge_settings)

    [{"box_settings" => box_settings, "provisioner_settings" => provisioner_settings}]
  end


  def k3s_cluster(cluster_values:)
    # three hosts - 1 server, 2 agents
    cluster_hosts = []
    server_host = {"box_settings" => {}, "provisioner_settings" => {}}

    k3s_cluster_values = cluster_values.is_a?(String) ? {"version" => cluster_values} : cluster_values
    service_version = get_service_version(service: 'k3s', version: k3s_cluster_values["version"])

    # server settings
    server_host["box_settings"]["name"] = k3s_cluster_values["server_name"] || box_name_string(service: 'k3s-server', version: k3s_cluster_values["version"])

    ["network", "memory", "cpu", "box"].each do |setting|
      server_host["box_settings"][setting] = k3s_cluster_values["server_#{setting}"] || @defaults[setting]
    end
    server_host["box_settings"]["ip_address"] = get_available_ip_address(host_name: server_host["box_settings"]["name"])

    # provisioner settings
    server_host["provisioner_settings"]['k3s_server_ip'] = server_host["box_settings"]["ip_address"]
    server_host["provisioner_settings"]['k3s_version']   = service_version
    server_host["provisioner_settings"]['k3s_role']      = "server"

    merge_settings = k3s_cluster_values["server_provisioner_settings"] || {}
    server_host["provisioner_settings"].merge!(merge_settings)
    cluster_hosts << server_host

    (1..2).to_a.each do |agent_count|
      box_settings = {}
      provisioner_settings = {}

      agent_name = k3s_cluster_values["agent_name"] || "k3s-agent"
      box_settings["name"] = box_name_string(service: agent_name, version: k3s_cluster_values["version"], count: agent_count)
      ["network", "memory", "cpu", "box"].each do |setting|
        box_settings[setting] = k3s_cluster_values["agent_#{setting}"] || @defaults[setting]
      end
      box_settings["ip_address"] = get_available_ip_address(host_name: box_settings["name"])

      # provisioner settings
      provisioner_settings['k3s_server_ip'] = server_host["box_settings"]["ip_address"]
      provisioner_settings['k3s_agent_ip'] = box_settings["ip_address"]
      provisioner_settings['k3s_version']   = service_version
      provisioner_settings['k3s_role']      = 'agent'

      merge_settings = k3s_cluster_values["agent_provisioner_settings"] || {}
      provisioner_settings.merge!(merge_settings)
      cluster_hosts << {"box_settings" => box_settings, "provisioner_settings" => provisioner_settings}
    end

    cluster_hosts
  end



  def get_service_version(service:, version:)
    # TODO strip the -ce off if present
    version_number = Gem::Version.new(version)
    (major,minor,patch,) = version_number.segments
    case service
    when 'gitlab'
       # TODO - latest version support
      "#{major}.#{minor || 0}.#{patch || 0}"
    when 'k3s'
      "v#{version}+k3s1"
    else
      version
    end
  end

  def box_name_string(service:, version:, count: nil)
    service_host = (count.nil?) ? service : sprintf("%s%02d",service,count)
    "#{service_host}-#{version.gsub('.','-')}#{@defaults['vagrant_domain']}"
  end

  def get_vmnet_configurable_ip_range
    dhcp_config = File.read(VMWARE_DHCP_CONFIG)
    # assumes default class C private addressing
    if(matches = dhcp_config.match(%r{subnet (?<subnet>[\d|\.]+)}))
      subnet = matches[:subnet]
      subnet_prefix = subnet.split('.').slice(0,3).join('.')

      if(matches = dhcp_config.match(%r{range (?<range_start>[\d|\.]+) (?<range_end>[\d|\.]+)}))
        dhcp_start = matches[:range_start].split('.').pop.to_i
        # .1 is reserved for the network
        # .2 for the dhcp server
        addresses = (3..(dhcp_start-1)).to_a.map{|address| "#{subnet_prefix}.#{address}"}
      end
    end
    addresses
  end


  # There are some limitations here - but it's a first iteration of
  # IP reservations so that I have a known IP address for both the
  # vagrant-hostsupdater plugin and for provisioning
  #
  # This will allocate IP Addresses by hostname
  #  - It doesn't clean up after itself
  #  - It re-uses the IP by hostname - so if a host in another
  #    host group ends up named the same - there could be a name
  #    conflict. It's expected that vm's will be halted and/or destroyed
  #    when switch between host groups

  def get_available_ip_address(host_name:)
    if(File.exists?(VAGRANT_HOSTIP_CACHE))
      hostip_cache =  YAML.load_file(VAGRANT_HOSTIP_CACHE)
    else
      hostip_cache = {}
    end

    if(!(allocated_ip = hostip_cache.key(host_name)))
      addresses = get_vmnet_configurable_ip_range
      allocated_ip = (addresses - hostip_cache.keys).first
      hostip_cache[allocated_ip] = host_name
      File.open(VAGRANT_HOSTIP_CACHE, "w") { |file| file.write(hostip_cache.to_yaml) }
    end
    allocated_ip
  end



end