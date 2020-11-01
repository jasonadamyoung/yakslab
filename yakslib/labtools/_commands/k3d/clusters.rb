require_relative '../labcommand'

module LabCommand
  class K3d
    class Clusters < LabCommand::Base

      def initialize(host:,options:)
        @host = host
        @k3d_remote_tools = LabTools::K3d::RemoteTools.new(host: @host)
      end

      def 🚀
        print_clusters = []
        spinner = TTY::Spinner.new("Getting cluster list for host: #{@host} :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @clusters = @k3d_remote_tools.clusters
        # get the kubeconfigs too
        @clusters.each do |cluster|
          if(cluster.running)
            kubeconfig_data = @k3d_remote_tools.kubeconfig_data(cluster.name)
            k8s_cluster = LabTools::Kubernetes::Cluster.new(with_data: kubeconfig_data)
            version = (server_version = k8s_cluster.server_version) ? server_version['gitVersion'] : 'unknown'
          else
            version = 'n/a'
          end
          print_clusters << {name: cluster.name, running: cluster.running, version: version}
        end
        spinner.stop('Done!')

        if(@clusters.blank?)
          puts "---"
          puts "No clusters found on host: #{@host}"
        end
        print_clusters.each do |cluster|
          puts "---"
          puts "Name:     #{cluster[:name]}"
          puts "Running:  #{cluster[:running] ? 'Yes' : 'No'}"
          puts "Version:  #{cluster[:version]}"
        end
      end


    end
  end

end
