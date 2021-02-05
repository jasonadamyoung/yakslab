require_relative '../labcommand'

module LabCommand
  class K3d
    class Start < LabCommand::Base

      def initialize(host:,cluster_name:,options:)
        @host = host
        @cluster_name = cluster_name
        @k3d_remote_tools = LabTools::K3d::RemoteTools.new(host: @host)
      end

      def 🚀
        spinner = TTY::Spinner.new("Starting cluster #{@cluster_name} on host: #{@host} :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @result = @k3d_remote_tools.start_cluster(@cluster_name)
        if(@result)
          spinner.success('Done!')
        else
          spinner.error('Failed!')
        end
      end

    end
  end
end
