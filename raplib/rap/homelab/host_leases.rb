require 'ipaddr'
require 'date'
require 'net/scp'
require 'louis'

module Rap
  module Homelab
    class HostLeases

      def initialize
        get_leases_list
      end


      def get_leases_list(force: false)
        if(@leases.nil? or force)
          @leases = []
          lease_list = Net::SCP::download!(Rap.settings.homelab_router,
                                          Rap.settings.homelab_sshuser,
                                          Rap.settings.homelab_hostleases).split("\n")
          lease_list.each do |lease_line|
            lease = lease_line.split(' ')
            lease_data = {}
            lease_data[:expiration]  = DateTime.strptime(lease[0],'%s')
            lease_data[:mac_address] = lease[1]
            lease_data[:ip_address]  = IPAddr.new(lease[2])
            lease_data[:hostname]    = lease[3]
            lease_data[:client_id]   = lease[4]
            @leases << lease_data
          end
        end
        @leases
      end
    end
  end
end
