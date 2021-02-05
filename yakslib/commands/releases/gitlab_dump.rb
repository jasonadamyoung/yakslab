require_relative '../labcommand'

module LabCommand
  module Releases
    class GitLabDump < LabCommand::Base
      DEFAULT_EDITION = 'EE'
      def initialize(dump_file:, options:)
        @dump_file = dump_file
        @edition = options[:edition] ? options[:edition].strip.upcase : DEFAULT_EDITION
        if(File.extname(@dump_file) == '.json')
          @output_format = 'json'
        else
          @output_format = 'yaml'
        end
        @release_tools = LabTools::Releases::GitLab.new
        @options = options
      end

      def 🚀
        if(@options[:update_cache])
          if(!@options[:quiet])
            spinner = TTY::Spinner.new("Getting GitLab release information from GitLab :spinner ...", format: :bouncing_ball)
            spinner.auto_spin
          end
          # force release and tag update
          @release_tools.refresh_releases_and_tags
        end

        @release_and_tag_data = @release_tools.grouped_tags_and_releases(format: 'filtered_hash')

        if(spinner)
          if(@release_and_tag_data)
            spinner.success('Done!')
          else
            spinner.error('Failed!')
          end
        end

        if(@release_and_tag_data)
          File.open(@dump_file, "w") do |file|
            if(@output_format == 'json')
              file.write(JSON.pretty_generate(@release_and_tag_data))
            else
              file.write(@release_and_tag_data.to_yaml)
            end
          end
          puts "Wrote GitLab release information to #{@dump_file}"
        end
      end
    end
  end
end
