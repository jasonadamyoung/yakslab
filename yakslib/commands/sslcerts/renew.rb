require_relative '../yakscommand'

module YaksCommand
  module SSLCerts
    class Renew < YaksCommand::Base
      def initialize(options: {})
        @options = options
        @force = options[:force].nil? ? false : options[:force]
        @prompt = prompt
        @shell = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
      end

      def 🚀
        command_options = ['--cron']
        if(@force)
          command_options << ['--force']
        end
        renew_command = "cd certificates && ./dehydrated #{command_options.join(' ')}"
        @shell.run(renew_command)
      end
    end
  end
end
