require_relative 'sub_command_base'

module YaksCLI
  class GitlabClusters < SubCommandBase
    class_option :profile, :type => :string, :default => Yaks.settings.default_gitlab_profile, :desc => "Name of LabClient profile to use in ~/.gitlab-labclient"
    class_option :group, :type => :string, :desc => "Group to add the integration to (a Group or Project is required)"
    class_option :project, :type => :string, :desc => "Project to add the integration to (a Project or Group is required)"

    desc "list", "Show configured cluster integrations for the specified group or project"
    def list
      require_relative '../commands/gitlab_clusters/list'
      LabCommand::GitLabClusters::List.new(options: options).🚀
    end

    desc "add CLUSTERNAME", "Add a cluster named CLUSTERNAME to the specified group or project"
    method_option :kubeconfig, :type => :string, :desc => "Kubeconfig file to use for the cluster (defaults to ./clusters/kubeconfig-CLUSTERNAME)"
    method_option :service_account_name, :type => :string, :default => 'gitlab-admin', :desc => "Service Account name for cluster integration"
    method_option :service_account_namespace, :type => :string, :default => 'kube-system', :desc => "Service Account namespace for cluster integration"
    method_option :create_service_account, :type => :boolean, :default => true, :desc => "Create Service Account if it doesn't already exist"
    method_option :make_cluster_admin, :type => :boolean, :default => true, :desc => "Make sure Service Account has cluster-admin if it doesn't already"
    method_option :cluster_options, :type => :hash, :default => {}, :desc => "Cluster options (environment_scope, domain, management_project_id, etc.)"
    def add(cluster_name)
      require_relative '../commands/gitlab_clusters/add'
      LabCommand::GitLabClusters::Add.new(cluster_name: cluster_name, options: options).🚀
    end

    desc "update CLUSTERNAME", "Update the cluster named CLUSTERNAME within the specified group or project"
    method_option :kubeconfig, :type => :string, :desc => "Kubeconfig file to use for the cluster (defaults to ./clusters/kubeconfig-CLUSTERNAME)"
    method_option :service_account_name, :type => :string, :default => 'gitlab-admin', :desc => "Service Account name for cluster integration"
    method_option :service_account_namespace, :type => :string, :default => 'kube-system', :desc => "Service Account namespace for cluster integration"
    method_option :cluster_options, :type => :hash, :default => {}, :desc => "Cluster options (environment_scope, domain, management_project_id, etc.)"
    def update(cluster_name)
      require_relative '../commands/gitlab_clusters/update'
      LabCommand::GitLabClusters::Update.new(cluster_name: cluster_name, options: options).🚀
    end


    desc "delete CLUSTERNAME", "Delete the cluster named CLUSTERNAME to the specified group or project"
    method_option :confirm_delete, :type => :boolean, :default => false, :desc => "Make sure the deletion is confirmed"
    def delete(cluster_name)
      require_relative '../commands/gitlab_clusters/delete'
      LabCommand::GitLabClusters::Delete.new(cluster_name: cluster_name, options: options).🚀
    end

  end
end