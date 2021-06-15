require_relative '../labcommand'

module LabCommand
  module SSLCerts
    class Deploy < LabCommand::Base
      def initialize(options: {})
        @options = options
        playbook_file = 'playbooks/deploycerts.yml'
        @ansible_playbook = LabTools::Ansible::Playbook.new(playbook_file: playbook_file,options: @options)
      end

      def 🚀
        puts "Running Ansible command: #{@ansible_playbook.command} "
        puts "---"
        aplay = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet, pty: true)
        aplay.run(@ansible_playbook.command, env: @ansible_playbook.environment)
      end
    end
  end
end
