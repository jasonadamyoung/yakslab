require_relative '../labcommand'

module LabCommand
  module Releases
    class K3d < LabCommand::Base
      def initialize(options:)
        @release_tools = LabTools::Releases::K3d.new
        @options = options
      end

      def 🚀
        spinner = TTY::Spinner.new("Query GitHub for K3d Releases :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @release_info = @release_tools.latest_release(format: 'filtered_hash')
        spinner.stop('Done!')
        puts "K3d Version: #{@release_info["name"]}"
        puts "Date Released: #{@release_info["date"].to_s}"
        puts "Checksum: #{@release_info["checksum"].to_s}"

        if(@options[:updateroleyaml])
          puts @options
          yaml_file = File.expand_path(@options[:updateroleyaml])
          if File.exists?(yaml_file)
            data = YAML.load(IO.read(yaml_file))

            if(data['k3d_version'])
              data['k3d_version'] = @release_info["name"]
              data['k3d_checksum'] = @release_info["checksum"]
              File.open(yaml_file, "w") do |file|
                file.write(data.to_yaml)
              end
              puts "Wrote k3d version to #{yaml_file}"
            end
          end
        end
      end
    end
  end
end
