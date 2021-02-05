require_relative '../labcommand'

module LabCommand
  class K3d
    class Create < LabCommand::Base

      def initialize(host:,cluster_name:,options:)
        @k3s_release = LabTools::Releases::K3s.new
        playbook_file = 'playbooks/k3d_cluster.yml'
        @options = options.merge(limit: host)
        extra_vars = {}
        extra_vars['k3d_cluster_name'] = cluster_name
        extra_vars['k3d_no_traefik'] = !options[:traefik]
        extra_vars['k3s_version'] = determine_k3s_version(options['k3s_version'])
        extra_vars['k3d_exposed_ports'] = options[:k3d_exposed_ports]
        @options[:extra_vars] = extra_vars
        @ansible_playbook = LabTools::Ansible::Playbook.new(playbook_file: playbook_file,options: @options)
        @prompt = prompt
      end

      def 🚀
        puts "Running Ansible command:\n#{@ansible_playbook.command} "
        puts "---"
        aplay = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet, pty: true)
        aplay.run(@ansible_playbook.command, env: @ansible_playbook.environment)
      end

      def determine_k3s_version(provided_version)
        if(k3s_version = @k3s_release.k3s_name_for_version(provided_version))
          k3s_version
        else
          @prompt.error "Unable to figure out the latest K3s release for version: #{provided_version}"
          exit(1)
        end
      end

    end
  end
end
