require_relative '../labcommand'

module LabCommand
  module Releases
    class K3sDump < LabCommand::Base
      def initialize(dump_file:, options:)
        @dump_file = dump_file
        @release_tools = LabTools::Releases::K3s.new
        @options = options
        if(File.extname(@dump_file) == '.json')
          @output_format = 'json'
        else
          @output_format = 'yaml'
        end
      end

      def 🚀
        if(!@options[:quiet])
          spinner = TTY::Spinner.new("Getting k3s release information from GitHub :spinner ...", format: :bouncing_ball)
          spinner.auto_spin
        end
        @releases = @release_tools.grouped_releases

        if(spinner)
          if(@releases)
            spinner.success('Done!')
          else
            spinner.error('Failed!')
          end
        end

        if(@releases)
          File.open(@dump_file, "w") do |file|
            if(@output_format == 'json')
              file.write(JSON.pretty_generate(@releases))
            else
              file.write(@releases.to_yaml)
            end
          end
          puts "Wrote k3s release information to #{@dump_file}"
        end
      end

    end
  end
end
