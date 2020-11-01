require_relative '../yakscommand'

module YaksCommand
  module SSLCerts
    class DehydratedInfo < YaksCommand::Base
      def initialize(options: {})
        @options = options
        @force = options[:force].nil? ? false : options[:force]
        @prompt = prompt
        @shell = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
      end

      def 🚀
        command_options = ['--env']
        run_command = "cd certificates && ./dehydrated #{command_options.join(' ')}"
        @shell.run(run_command)
      end
    end
  end
end
