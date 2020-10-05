require_relative '../../command'

module Yaks
  module Commands
    class K3s
      class Latest < Yaks::Command
        def initialize(options:)
          @k3s_tools = Yaks::K3sTools.new
          @releases = @k3s_tools.get_k3s_latest_releases
          @options = options
        end

        def 🚀
          @releases.each do |version,release_info|
            puts "---"
            puts "Kubernetes #{version}"
            puts "K3s Version: #{release_info[:name]}"
            puts "Date Released: #{release_info[:date].to_s}"
          end
        end
      end
    end
  end
end
