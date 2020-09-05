require "net/http"
require 'ipaddr'
require "droplet_kit"


module Rap
  class Homelab

    def initialize(options={})
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
          @home_dns_record = doclient.domain_records.find(for_domain: Rap.settings.home_domain, id: Rap.settings.home_domain_homeip_record)
        rescue DropletKit::Error => exception
          @home_dns_record = nil
        end
      end
      @home_dns_record
    end

    def home_dns_record_ip
      if(ipaddr = home_dns_record&.data )
        IPAddr.new(ipaddr)
      else
        nil
      end
    end

    def update_home_dns_record(force = false)
      return false if home_dns_record.nil?
      return false if home_ip.nil?
      if(!(home_ip == home_dns_record_ip) or force)
        domain_record = home_dns_record
        domain_record.data = home_ip.to_s
        begin
          @home_dns_record = doclient.domain_records.update(domain_record, for_domain: Rap.settings.home_domain, id: Rap.settings.home_domain_homeip_record)
          return true
        rescue DropletKit::Error => exception
          return false
        end
      else
        true
      end
    end

    def doclient
      if(@doclient.nil?)
        @doclient = DropletKit::Client.new(access_token: Rap.settings.homelab_do_token)
      end
      @doclient
    end

  end
end