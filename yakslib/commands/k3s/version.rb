require_relative '../labcommand'

module LabCommand
  class K3s
    class Version < LabCommand::Base

      def initialize(host:,options:)
        @host = host
        @k3s_remote_tools = LabTools::K3s::RemoteTools.new(host: @host)
      end

      def 🚀
        print_clusters = []
        spinner = TTY::Spinner.new("Getting cluster information for host: #{@host} :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        kubeconfig_data = @k3s_remote_tools.kubeconfig_data
        @k8s_cluster = LabTools::Kubernetes::Cluster.new(with_data: kubeconfig_data)
        @k8s_version = @k8s_cluster.server_version
        spinner.stop('Done!')

        if(@k8s_version.nil? or @k8s_version.empty?)
          puts "No k3s cluster found on host: #{@host}"
        else
          puts JSON.pretty_generate(@k8s_version)
        end
      end


    end
  end

end
