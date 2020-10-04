require_relative '../command'

module Yaks
  module Commands
    class Update < Yaks::Command
      def initialize(limitto,options)
        @options = options.merge({limit: limitto})
        if(@options[:no_reboot])
          playbook_file = 'playbooks/updates_only.yml'
        else
          playbook_file = 'playbooks/updates_with_reboot.yml'
        end
        @ansible_playbook = Yaks::AnsiblePlaybook.new(playbook_file: playbook_file,options: @options)
      end

      def 🚀
        puts "Running Ansible command: #{@ansible_playbook.command} "
        puts "---"
        aplay = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
        aplay.run(@ansible_playbook.command, env: @ansible_playbook.environment)
      end
    end
  end
end
