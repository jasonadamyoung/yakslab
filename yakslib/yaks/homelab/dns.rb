require "net/http"
require 'ipaddr'
require "droplet_kit"

module Yaks
  module Homelab
    class Dns


      def initialize(domain: Yaks.settings.home_domain)
        @domain = domain
        doclient
      end

      def doclient
        if(@doclient.nil?)
          @doclient = DropletKit::Client.new(access_token: Yaks.settings.homelab_do_token)
        end
        @doclient
      end

      def get_dns_record_for_record_id(dns_record_id:)
        begin
          doclient.domain_records.find(for_domain: @domain, id: dns_record_id)
        rescue DropletKit::Error => exception
          nil
        end
      end

      def dns_record_ip(dns_record:)
        if(ipaddr = dns_record&.data)
          IPAddr.new(ipaddr)
        else
          nil
        end
      end

      def update_dns_record(dns_record:)
        begin
          @doclient.domain_records.update(dns_record, for_domain: @domain, id: dns_record.id)
        rescue DropletKit::Error => exception
          return false
        end
      end

      def create_dns_record(dns_record:)
        begin
          @doclient.domain_records.update(dns_record, for_domain: @domain)
        rescue DropletKit::Error => exception
          return false
        end
      end

      def all_dns_records
        all_records = []
        begin
          paginated_records = @doclient.domain_records.all(for_domain: @domain)
          paginated_records.each do |dr|
            all_records << dr
          end
        rescue DropletKit::Error => exception
          return false
        end
        all_records
      end

      def make_dns_record(name:, data:, type: 'A', ttl: 300)
        DropletKit::DomainRecord.new(type: type, name: name, data: data, ttl: ttl)
      end


    end
  end
end
