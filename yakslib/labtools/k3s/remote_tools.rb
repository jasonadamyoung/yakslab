require 'net/ssh'
require 'net/scp'
require 'yaml'

module LabTools
  module K3s
    class RemoteTools

      def initialize(host:)
        @host = host
      end

      def kubeconfig_data(force_update: false)
        if(@kubeconfig.nil? or force_update)
          Net::SSH.start(@host) do |ssh|
            @raw_kubeconfig_output = ssh.scp.download!("/etc/rancher/k3s/k3s.yaml")
          end

          if(@raw_kubeconfig_output)
            @kubeconfig = @raw_kubeconfig_output.gsub('127.0.0.1',@host).to_s
          else
            @kubeconfig = nil
          end
        end
        @kubeconfig
      end

    end
  end
end