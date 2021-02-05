require_relative '../labcommand'

module LabCommand
  class K3d
    class Delete < LabCommand::Base

      def initialize(host:,cluster_name:,options:)
        playbook_file = 'playbooks/k3d_cleanup_cluster.yml'
        @options = options.merge(limit: host)
        extra_vars = {}
        extra_vars['k3d_cluster_name'] = cluster_name
        @options[:extra_vars] = extra_vars
        @ansible_playbook = LabTools::Ansible::Playbook.new(playbook_file: playbook_file,options: @options)
      end

      def 🚀
        if(!@options[:confirm_delete])
          puts "Please set --confirm_delete to confirm the cluster deletion"
          return
        end
        puts "Running Ansible command:\n#{@ansible_playbook.command} "
        puts "---"
        aplay = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet, pty: true)
        aplay.run(@ansible_playbook.command, env: @ansible_playbook.environment)
      end

    end
  end
end
