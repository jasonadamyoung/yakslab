require_relative '../labcommand'
require 'yaml'
require 'tty-spinner'

module LabCommand
  module K3s
    class Dump < LabCommand::Base
      def initialize(dump_file:, options:)
        @dump_file = dump_file
        @options = options
        @k3s_tools = LabTools::K3s::VersionTools.new
      end

      def 🚀
        if(!@options[:quiet])
          spinner = TTY::Spinner.new("Getting k3s release information from GitHub :spinner ...", format: :bouncing_ball)
          spinner.auto_spin
        end
        @releases = @k3s_tools.get_grouped_k3s_release_info

        if(spinner)
          if(@releases)
            spinner.success('Done!')
          else
            spinner.error('Failed!')
          end
        end

        if(@releases)
          File.open(@dump_file, "w") do |file|
            file.write(@releases.to_yaml)
          end
          puts "Wrote k3s release information to #{@dump_file}"
        end
      end

    end
  end
end
