require "net/http"
require 'ipaddr'

module Yaks
  module Homelab
    class HomeAddress

      def initialize()
        @home_domain_dns = Yaks::Homelab::Dns.new
        home_ip
      end

      def home_ip
        if(@home_ip.nil?)
          string_ip = Net::HTTP.get(URI("https://api.ipify.org"))
          @home_ip = IPAddr.new(string_ip)
        end
        @home_ip
      end


      def home_dns_record
        if(@home_dns_record.nil?)
          begin
            @home_dns_record = @home_domain_dns.get_dns_record_for_record_id(dns_record_id: Rap.settings.home_domain_homeip_record)
          rescue DropletKit::Error => exception
            @home_dns_record = nil
          end
        end
        @home_dns_record
      end

      def home_dns_record_ip
        @home_domain_dns.dns_record_ip(dns_record: home_dns_record)
      end


      def update_home_dns_record(force: false)
        return false if home_dns_record.nil?
        return false if home_ip.nil?
        if(!(home_ip == home_dns_record_ip) or force)
          dns_record = home_dns_record
          dns_record.data = home_ip.to_s
          @home_domain_dns.update_dns_record(dns_record: dns_record)
        else
          true
        end
      end
    end
  end
end