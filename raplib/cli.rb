require 'thor'
require 'rap'

module Rap
  class CLI < Thor
    include Thor::Actions
    class_option :quiet, :type => :boolean, :default => false, :desc => "If true, Don't echo the command to stdout"
    class_option :dryrun, :type => :boolean, :default => false, :desc => "If true, echo the command that would be run to stdout"
    class_option :verbosity, :type => :numeric, :default => 0, :desc => "ansible-playbook verbosity (0=none,1=-v,2=-vv,3=-vvv,4=-vvvv)"
    # these are not the tasks that you seek
    def self.source_root
      File.expand_path(File.dirname(__FILE__) + "/..")
    end

    no_tasks do

      def playbook_verbosity(options)
        [verbosity_value(options[:verbosity])].compact
      end

      def verbosity_limits_and_tags(options)
        playbook_options = playbook_verbosity(options)
        if(options[:limit])
          playbook_options << "--limit=#{options[:limit]}"
        end
        if(options[:tags])
          playbook_options << "--tags=#{options[:tags]}"
        end
        playbook_options
      end

      def verbosity_value(verbosity_value)
        if(verbosity_value == 0)
          nil
        elsif(verbosity_value.between?(1,4))
          '-' + 'v' * verbosity_value
        else
          nil
        end
      end

    end

    # ansible-playbook tasks
    desc "go PLAYBOOK", "Run ansible-playbook against the specified PLAYBOOK with limited options"
    method_option :limit, :desc => "Host or host pattern to limit the play to.  Passed to ansible-playbook"
    method_option :tags, :desc => "Tags to limit the play to.  Passed to ansible-playbook"
    def go(playbook)
      playbook_options = verbosity_limits_and_tags(options)
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!
    end

    # ansible-playbook tasks
    desc "raw_go PLAYBOOK", "Run ansible-playbook against the specified PLAYBOOK - allows raw arguments to be passed to ansible-playbook"
    def raw_go(*argumentlist)
      # method options above are popped off the list
      playbook = argumentlist.pop
      playbook_options = argumentlist
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!

    end

    desc "up HOST(s)", "Run updates against the specified host or host group "
    method_option :no_reboot, :type => :boolean, :default => false, :desc => "Run updates only. Do not reboot the host(s)."
    def up(limitto)
      playbook_options = ["--limit=#{limitto}"]
      if(options[:no_reboot])
        playbook = 'playbooks/updates_only.yml'
      else
        playbook = 'playbooks/updates_with_reboot.yml'
      end
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!
    end

    desc "deploy APPLICATION", "Deploys an app"
    def deploy(application)
      playbook_options = ["--limit=#{application}"]
      playbook = 'playbooks/digitalocean/appdeploy.yml'
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!
    end

    desc "ping", "Runs an ansible ping playbook"
    def ping
      playbook_options = verbosity_limits_and_tags(options)
      playbook = 'playbooks/utilities/ping.yml'
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!
    end

    desc "rekey  HOST(s)", "Run the sshkeys playbook to rekey host or host group"
    def rekey(limitto)
      playbook = "playbooks/utilities/sshkeys.yml"
      playbook_options = ["--limit=#{limitto}"]
      aplay = Rap::Aplay.new(playbook_options: playbook_options,
                                     playbook: playbook,
                                     quiet: options[:quiet],
                                     dryrun: options[:dryrun])
      aplay.go!
    end

    # dehydrated tasks
    desc "renewcerts", "Use dehydrated and the digitalocean dehydrated hook script to renew SSL certificates"
    method_option :force, :type => :boolean, :default => false, :desc => "Force renewal even if it isn't time yet to do so"
    method_option :cleanup, :type => :boolean, :default => true, :desc => "Cleanup old scripts afterward (dehydrated --cleanup)"
    def renewcerts
      dehydrated = Rap::Dehydrated.new(force: options[:force],
                                               quiet: options[:quiet],
                                               dryrun: options[:dryrun])
      dehydrated.renew!

      if(options[:cleanup])
        dehydrated.cleanup
      end
    end


    # vault tasks
    desc "encryptvault VAULTFILE", "Use ansible-vault to encrypt a decrypted vault file and save it as VAULTFILE (specify all to encrypt all found vault files)"
    method_option :force, :type => :boolean, :default => false, :desc => "Force encryption even if the encrypted file is newer"
    def encryptvault(vaultfile)
      if(vaultfile == 'all')
        vaultfiles = Rap::Vault.find_all_vault_files
      else
        vaultfiles = [vaultfile]
      end
      vaultfiles.each do |vf|
        vault = Rap::Vault.new(force: options[:force],
                                       quiet: options[:quiet],
                                       dryrun: options[:dryrun],
                                       vault: vf)
        vault.encrypt!
      end
    end

    desc "decryptvault VAULTFILE", "Use ansible-vault to decrypt VAULTFILE into a decrypted vault file (specify all to decrypt all found vault files)"
    method_option :force, :type => :boolean, :default => false, :desc => "Force decryption even if the decrypted file is newer"
    def decryptvault(vaultfile)
      if(vaultfile == 'all')
        vaultfiles = Rap::Vault.find_all_vault_files
      else
        vaultfiles = [vaultfile]
      end
      vaultfiles.each do |vf|
        vault = Rap::Vault.new(force: options[:force],
                                       quiet: options[:quiet],
                                       dryrun: options[:dryrun],
                                       vault: vf)
        vault.decrypt!
      end
    end

    desc "listvaults", "List known vault files"
    def listvaults
      vaultfiles = Rap::Vault.find_all_vault_files
      puts "Found #{vaultfiles.size} files ending in _vault.yml:"
      vaultfiles.each do |vf|
        puts "  #{vf}"
      end
    end

  end
end
