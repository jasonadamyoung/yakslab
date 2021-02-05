require_relative '../labcommand'

module LabCommand
  module GitLabClusters
    class Delete < LabCommand::Base
      def initialize(cluster_name:, options:)
        @options = options
        @profile = @options[:profile]
        @cluster_name = cluster_name

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

        if(@options[:kubeconfig])
          @kubeconfig_file = @options[:kubeconfig]
          @cluster = LabTools::Kubernetes::Cluster.new(with_file: @kubeconfig_file)
        end

        @cluster_integration = Sup::GitLab::ClusterIntegration.new(service_account: nil, group: @group, project: @project, profile: @profile)
        @prompt = prompt
      end

      def 🚀
        if(!@options[:confirm_delete])
          @prompt.warn "Please set --confirm-delete to confirm the cluster deletion"
          return
        end
        group_or_project_name = @cluster_integration.group_or_project_name
        success = @cluster_integration.delete(cluster_name: @cluster_name)
        if(success)
          @prompt.ok "Deleted cluster #{@cluster_name} from #{group_or_project_name}"
        else
          @prompt.error "Unable to delete cluster #{@cluster_name} from #{group_or_project_name}"
        end

        # TODO check for gitlab_managed_apps namespace
        @prompt.warn "Deleting the cluster integration doesn't delete any gitlab-managed-apps resources in the cluster. Please check these manually."

      end

    end
  end
end
