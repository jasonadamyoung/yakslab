require_relative '../labcommand'

module LabCommand
  module SSLCerts
    class DehydratedCleanup < LabCommand::Base
      def initialize(options: {})
        @options = options
        @force = options[:force].nil? ? false : options[:force]
        @prompt = prompt
        @shell = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
      end

      def 🚀
        command_options = ['--cleanup']
        run_command = "cd certificates && ./dehydrated #{command_options.join(' ')}"
        @shell.run(run_command)
      end
    end
  end
end
