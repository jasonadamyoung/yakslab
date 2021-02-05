
require_relative '../labcommand'

module LabCommand
  module Releases
    class K3s < LabCommand::Base
      def initialize(options:)
        @release_tools = LabTools::Releases::K3s.new
        @options = options
      end

      def 🚀
        spinner = TTY::Spinner.new("Query GitHub for K3s Releases :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @releases = @release_tools.latest_releases
        spinner.stop('Done!')
        @releases.each do |version,release_info|
          puts "---"
          puts "Kubernetes #{version}"
          puts "K3s Version: #{release_info["name"]}"
          puts "Date Released: #{release_info["date"].to_s}"
          puts "Checksum: #{release_info["checksum"].to_s}"
        end
      end
    end
  end
end
