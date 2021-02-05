require_relative 'sub_command_base'

module YaksCLI
  class K3d < SubCommandBase
    class_option :host, :required => true, :type => :string, :desc => "Remote k3d host"

    desc "create CLUSTERNAME", "Create a new remote cluster on the specified k3d host using Ansible"
    method_option :traefik, :type => :boolean, :default => false, :desc => "Install the included Traefik Ingress"
    method_option :k3s_version, :type => :string, :default => '1.18', :desc => "Supports a specific version name (e.g. v1.16.15+k3s1), gets the latest major.minor (e.g. 1.16) or latest"
    method_option :k3d_exposed_ports, :type => :array, :default=>["80","443"], :desc => "Ports exposed by k3d for this cluster"
    method_option :dry_run,   :type => :boolean, :default => false, :desc => "Dry-run - don't actually run the command"
    def create(cluster_name)
      require_relative '../commands/k3d/create'
      LabCommand::K3d::Create.new(host: options[:host], cluster_name: cluster_name, options: options).🚀
    end

    desc "delete CLUSTERNAME", "Create a new remote cluster on the specified k3d host using Ansible"
    method_option :confirm_delete, :type => :boolean, :default => false, :desc => "Make sure the deletion is confirmed"
    method_option :dry_run,   :type => :boolean, :default => false, :desc => "Dry-run - don't actually run the command"
    def delete(cluster_name)
      require_relative '../commands/k3d/delete'
      LabCommand::K3d::Delete.new(host: options[:host], cluster_name: cluster_name, options: options).🚀
    end

    desc "list", "List the clusters on the specified k3d host"
    def list
      require_relative '../commands/k3d/list'
      LabCommand::K3d::List.new(host: options[:host], options: options).🚀
    end

    desc "start CLUSTERNAME", "Start CLUSTERNAME on HOST"
    def start(cluster_name)
      require_relative '../commands/k3d/start'
      LabCommand::K3d::Start.new(host: options[:host], cluster_name: cluster_name, options: options).🚀
    end

    desc "stop CLUSTERNAME", "Start CLUSTERNAME on HOST"
    def stop(cluster_name)
      require_relative '../commands/k3d/stop'
      LabCommand::K3d::Stop.new(host: options[:host], cluster_name: cluster_name, options: options).🚀
    end

  end
end