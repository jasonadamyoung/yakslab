require_relative '../labcommand'

module LabCommand
  module GitLabClusters
    class Update < LabCommand::Base
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

        @service_account = LabTools::Kubernetes::ServiceAccount.new(cluster: @cluster, name: @options[:service_account_name], namespace: @options[:service_account_namespace])
        @cluster_integration = Sup::GitLab::ClusterIntegration.new(service_account: @service_account, group: @group, project: @project, profile: @profile)
        @prompt = prompt
      end

      def 🚀
        group_or_project_name = @cluster_integration.group_or_project_name
        add_spinner = TTY::Spinner.new("Updating cluster #{@cluster_name} for #{group_or_project_name} :spinner ...", format: :bouncing_ball)
        add_spinner.auto_spin
        success = @cluster_integration.update(cluster_name: @cluster_name, cluster_options: @options[:cluster_options].symbolize_keys)
        if(success)
          add_spinner.success('Done!')
          cluster_name = @options[:cluster_options]["name"] || @cluster_name
          cluster_info = @cluster_integration.cluster_information(cluster_name: cluster_name)
          @prompt.ok "Cluster URL: #{@cluster_integration.group_or_project_url}/-/clusters/#{cluster_info["id"]}"
        else
          add_spinner.error('Failed!')
        end
      end

    end
  end
end
