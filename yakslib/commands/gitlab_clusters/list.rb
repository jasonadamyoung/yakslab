require_relative '../labcommand'

module LabCommand
  module GitLabClusters
    class List < LabCommand::Base
      def initialize(options:)
        @options = options

        if(@options[:group])
          @scope = 'group'
          @group = @options[:group]
          @project = ''
        elsif(@options[:project])
          @scope = 'project'
          @project = @options[:project]
          @group = ''
        else
          @project = ''
          @group = ''
        end

        @profile = @options[:profile]
        @cluster_integration = LabTools::GitLab::ClusterIntegration.new(service_account: nil, group: @group, project: @project, profile: @profile)
      end

      def 🚀
        spinner = TTY::Spinner.new("Getting cluster list for #{@scope}: #{@group_or_project} :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        @clusters = @cluster_integration.clusters_information
        spinner.stop('Done!')
        if(@clusters.blank?)
          puts "---"
          puts "No clusters found for #{@scope}: #{@group_or_project}"
        end
        @clusters.each do |cluster|
          puts "---"
          puts "Name:     #{cluster["name"]}"
          puts "ID:       #{cluster["id"]}"
          puts "Created:  #{cluster["created_at"]}"
          puts "Type:     #{cluster["type"]}"
        end
      end

    end
  end
end
