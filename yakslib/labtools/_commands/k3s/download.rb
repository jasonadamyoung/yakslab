require_relative '../labcommand'
require 'down'
require 'tty-spinner'

module LabCommand
  module K3s
    class Download < LabCommand::Base
      def initialize(version:, options:)
        @version = version
        @k3s_tools = LabTools::K3s::VersionTools.new
        @releases = @k3s_tools.get_k3s_latest_releases
        @options = options
        @prompt = prompt
        @force = options[:force].nil? ? false : options[:force]
      end

      def 🚀
        if(@version == 'all')
          releases = @releases.values
        else
          releases = [@releases[@version]]
        end
        releases.each do |release_info|
          download_release(release_info: release_info)
        end
      end

      def download_release(release_info:)
        target_file = target_file(k3s_release_name: release_info[:name])
        if(!@force)
          if(File.exists?(target_file))
            @prompt.warn "The target file #{target_file} exists, not downloading (Specify --force to override)"
            return false
          end
        end

        download = TTY::Spinner.new("[:spinner] Downloading #{release_info[:name]}")
        download.run do |ds|
          Down.download(release_info[:download_url], destination: target_file)
        end
        download.success('(done!)')
      end

      def target_file(k3s_release_name:)
        File.join(@options[:cache_directory],"k3s-#{k3s_release_name}")
      end

    end
  end
end
