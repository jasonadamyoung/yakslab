require_relative '../labcommand'

module LabCommand
  module Ansible
    class Update < LabCommand::Base
      def initialize(limitto,options)
        @options = options.merge({limit: limitto})
        if(@options[:no_reboot])
          playbook_file = 'playbooks/updates_only.yml'
        else
          playbook_file = 'playbooks/updates_with_reboot.yml'
        end
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
