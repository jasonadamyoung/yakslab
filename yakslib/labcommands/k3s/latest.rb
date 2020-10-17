require_relative '../labcommand'

module LabCommand
  module K3s
    class Latest < LabCommand::Base
      def initialize(options:)
        @k3s_tools = LabTools::K3s::VersionTools.new
        @options = options
      end

      def 🚀
        spinner = TTY::Spinner.new("Query GitHub for K3s Releases :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @releases = @k3s_tools.get_k3s_latest_releases
        spinner.stop('Done!')
        @releases.each do |version,release_info|
          puts "---"
          puts "Kubernetes #{version}"
          puts "K3s Version: #{release_info[:name]}"
          puts "Date Released: #{release_info[:date].to_s}"
          puts "Checksum: #{release_info[:checksum].to_s}"
        end
      end
    end
  end
end
