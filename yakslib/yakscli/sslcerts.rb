require_relative 'sub_command_base'

module YaksCLI
  class Sslcerts < SubCommandBase
    class_option :dry_run,   :type => :boolean, :default => false, :desc => "Dry-run - don't actually run the command"

    desc "renew", "Renew all SSLCerts using Dehydrated"
    method_option :force, :type => :boolean, :default => false, :desc => "Force renewal"
    def renew
      require_relative '../commands/sslcerts/renew'
      YaksCommand::SSLCerts::Renew.new(options: options).🚀
    end

    desc "dehydrated_info", "Show Dehydrated Environment Information"
    def dehydrated_info
      require_relative '../commands/sslcerts/dehydrated_info'
      YaksCommand::SSLCerts::DehydratedInfo.new(options: options).🚀
    end

    desc "dehydrated_cleanup", "Cleanup Dehydrated Certs"
    def dehydrated_cleanup
      require_relative '../commands/sslcerts/dehydrated_cleanup'
      YaksCommand::SSLCerts::DehydratedCleanup.new(options: options).🚀
    end

    desc "deploy", "Deploy certs to hosts"
    method_option :verbosity, :type => :numeric, :default => 0, :desc => "ansible-playbook verbosity (0=none,1=-v,2=-vv,3=-vvv,4=-vvvv)"
    def deploy
      require_relative '../commands/sslcerts/deploy'
      YaksCommand::SSLCerts::Deploy.new(options: options).🚀
    end

  end
end