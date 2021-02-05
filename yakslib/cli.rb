require 'thor'
require 'yaks'
require 'amazing_print'
require 'yakscli/avault'
require 'yakscli/k3s'
require 'yakscli/k3d'
require 'yakscli/releases'
require 'yakscli/sslcerts'
require 'yakscli/subtest'
require 'yakscli/gitlab_clusters'

module YaksCLI
  class CLI < Thor
    include Thor::Actions
    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end

    def self.exit_on_failure?
      false
    end

    desc "avault", "Execute Ansible Vault commands"
    subcommand "avault", YaksCLI::Avault

    desc "k3s", "Execute K3s commands"
    subcommand "k3s", YaksCLI::K3s

    desc "k3d", "Execute K3d commands"
    subcommand "k3d", YaksCLI::K3d

    desc "releases", "Get Release Information"
    subcommand "releases", YaksCLI::Releases

    desc "sslcerts", "Execute SSLCerts commands"
    subcommand "sslcerts", YaksCLI::Sslcerts

    desc "subtest", "Execute Subtest commands"
    subcommand "subtest", YaksCLI::Subtest

    desc "gitlab-clusters", "GitLab Cluster Tools"
    subcommand "gitlab_clusters", YaksCLI::GitlabClusters

    desc "update HOST(s)", "Run updates via ansible against the specified host or host group "
    method_option :verbosity, :type => :numeric, :default => 0, :desc => "ansible-playbook verbosity (0=none,1=-v,2=-vv,3=-vvv,4=-vvvv)"
    method_option :no_reboot, :type => :boolean, :default => false, :desc => "Run updates only. Do not reboot the host(s)."
    method_option :dry_run,   :type => :boolean, :default => false, :desc => "Dry-run - don't actually run the command"

    def update(limitto)
      require_relative 'commands/ansible/update'
      LabCommand::Ansible::Update.new(limitto,options).🚀
    end
  end

end
