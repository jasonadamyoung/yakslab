require_relative '../labcommand'

module LabCommand
  module GitLabClusters
    class Add < LabCommand::Base
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
        @cluster_integration = LabTools::GitLab::ClusterIntegration.new(service_account: @service_account, group: @group, project: @project, profile: @profile)
        @prompt = prompt
      end

      def 🚀
        if(!(server_version = @cluster.server_version))
          @prompt.error "Unable to connect to the kubernetes cluster to get the server version"
          return false
        end

        check_or_create_service_account

        group_or_project_name = @cluster_integration.group_or_project_name
        add_spinner = TTY::Spinner.new("Adding cluster #{@cluster_name} to #{group_or_project_name} :spinner ...", format: :bouncing_ball)
        add_spinner.auto_spin
        success = @cluster_integration.create(cluster_name: @cluster_name, cluster_options: @options[:cluster_options].symbolize_keys)
        if(success)
          add_spinner.success('Done!')
          cluster_info = @cluster_integration.cluster_information(cluster_name: @cluster_name)
          @prompt.ok "Cluster URL: #{@cluster_integration.group_or_project_url}/-/clusters/#{cluster_info["id"]}"
        else
          add_spinner.error('Failed!')
        end
      end


      def check_or_create_service_account
        created_account = false
        spinner = TTY::Spinner.new("Checking for/Creating Service Account :spinner ...", format: :bouncing_ball)
        spinner.auto_spin
        if(!@service_account.exists? and @options[:create_service_account])
          if(@options[:make_cluster_admin])
            @service_account.create_cluster_admin_account
          else
            @service_account.create
          end
          created_account = true
        else
          if(!@service_account.is_cluster_admin? and options[:make_cluster_admin])
            @service_account.create_cluster_admin_account
            created_account = true
          end
        end
        if(created_account)
          # wait 5 seconds for kubernetes to create the account
          sleep(5)
        end
        spinner.stop('Done!')
      end

    end
  end
end
