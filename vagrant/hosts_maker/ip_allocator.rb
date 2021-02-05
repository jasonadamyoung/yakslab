module VagrantHosts
  class IPAllocator
    VMWARE_DHCP_CONFIG = "/Library/Preferences/VMware\ Fusion/vmnet8/dhcpd.conf"
    VAGRANT_HOSTIP_CACHE = ".vagrant_hostip_cache.yml"

    def initialize(configuration_root:, address_pool: "get_from_vmware")
      @configuration_root = configuration_root
      @vagrant_hostip_cache = File.join(@configuration_root,VAGRANT_HOSTIP_CACHE)
      if(address_pool.is_a?(String) and address_pool == 'get_from_vmware')
        @address_pool = get_vmnet_configurable_ip_range
      else
        # assume pool is an array
        @address_pool = address_pool
      end
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
      if(File.exists?(@vagrant_hostip_cache))
        hostip_cache =  YAML.load_file(@vagrant_hostip_cache)
      else
        hostip_cache = {}
      end

      if(!(allocated_ip = hostip_cache.key(host_name)))
        allocated_ip = (@address_pool - hostip_cache.keys).first
        hostip_cache[allocated_ip] = host_name
        File.open(@vagrant_hostip_cache, "w") { |file| file.write(hostip_cache.to_yaml) }
      end
      allocated_ip
    end
  end
end