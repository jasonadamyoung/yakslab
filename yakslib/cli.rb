require 'thor'
require 'yaks'
require 'cli/avault'
require 'cli/k3s'

module YaksCLI
  class CLI < Thor
    include Thor::Actions
    class_option :quiet, :type => :boolean, :default => false, :desc => "If true, Don't echo the command to stdout"
    class_option :dry_run, :type => :boolean, :default => false, :desc => "If true, echo the command that would be run to stdout"
    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end

    desc "avault", "Execute Ansible Vault commands"
    subcommand "avault", YaksCLI::Avault

    desc "k3s", "Execute K3s commands"
    subcommand "k3s", YaksCLI::K3s

    # also defined as ansible update
    desc "update HOST(s)", "Run updates via ansible against the specified host or host group "
    method_option :verbosity, :type => :numeric, :default => 0, :desc => "ansible-playbook verbosity (0=none,1=-v,2=-vv,3=-vvv,4=-vvvv)"
    method_option :no_reboot, :type => :boolean, :default => false, :desc => "Run updates only. Do not reboot the host(s)."
    def update(limitto)
      require_relative 'commands/update'
      Yaks::Commands::Update.new(limitto,options).🚀
    end

    # ansible-playbook tasks
    # desc "go PLAYBOOK", "Run ansible-playbook against the specified PLAYBOOK with limited options"
    # method_option :limit, :desc => "Host or host pattern to limit the play to.  Passed to ansible-playbook"
    # method_option :tags, :desc => "Tags to limit the play to.  Passed to ansible-playbook"
    # def go(playbook)
    #   playbook_options = verbosity_limits_and_tags(options)
    #   aplay = Rap::Aplay.new(playbook_options: playbook_options,
    #                                  playbook: playbook,
    #                                  quiet: options[:quiet],
    #                                  dryrun: options[:dryrun])
    #   aplay.go!
    # end

    # ansible-playbook tasks
    # desc "raw_go PLAYBOOK", "Run ansible-playbook against the specified PLAYBOOK - allows raw arguments to be passed to ansible-playbook"
    # def raw_go(*argumentlist)
    #   # method options above are popped off the list
    #   playbook = argumentlist.pop
    #   playbook_options = argumentlist
    #   aplay = Rap::Aplay.new(playbook_options: playbook_options,
    #                                  playbook: playbook,
    #                                  quiet: options[:quiet],
    #                                  dryrun: options[:dryrun])
    #   aplay.go!

    # end



    # desc "ping", "Runs an ansible ping playbook"
    # def ping
    #   playbook_options = verbosity_limits_and_tags(options)
    #   playbook = 'playbooks/ping.yml'
    #   aplay = Rap::Aplay.new(playbook_options: playbook_options,
    #                                  playbook: playbook,
    #                                  quiet: options[:quiet],
    #                                  dryrun: options[:dryrun])
    #   aplay.go!
    # end

    # desc "rekey  HOST(s)", "Run the sshkeys playbook to rekey host or host group"
    # def rekey(limitto)
    #   playbook = "playbooks/sshkeys.yml"
    #   playbook_options = ["--limit=#{limitto}"]
    #   aplay = Rap::Aplay.new(playbook_options: playbook_options,
    #                                  playbook: playbook,
    #                                  quiet: options[:quiet],
    #                                  dryrun: options[:dryrun])
    #   aplay.go!
    # end

    # # dehydrated tasks
    # desc "renewcerts", "Use dehydrated and the digitalocean dehydrated hook script to renew SSL certificates"
    # method_option :force, :type => :boolean, :default => false, :desc => "Force renewal even if it isn't time yet to do so"
    # method_option :cleanup, :type => :boolean, :default => true, :desc => "Cleanup old scripts afterward (dehydrated --cleanup)"
    # def renewcerts
    #   dehydrated = Rap::Dehydrated.new(force: options[:force],
    #                                            quiet: options[:quiet],
    #                                            dryrun: options[:dryrun])
    #   dehydrated.renew!

    #   if(options[:cleanup])
    #     dehydrated.cleanup
    #   end
    # end

  end
end
