require_relative '../labcommand'

module LabCommand
  module Avault
    class Encrypt < LabCommand::Base
      def initialize(vault_file:, options: {})
        @vault_file = vault_file
        @options = options
        @force = options[:force].nil? ? false : options[:force]
        @prompt = prompt
        @shell = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
      end

      def 🚀
        if(@vault_file == 'all')
          vaultfiles = LabTools::AnsibleVault.find_all_vault_files
        else
          vaultfiles = [@vault_file]
        end
        vaultfiles.each do |vf|
          encrypt_vault(vault_file: vf)
        end
      end

      def encrypt_vault(vault_file: )
        puts "Encrypting #{vault_file}"
        avault = LabTools::AnsibleVault.new(vault_file: vault_file, options: @options)
        if(!avault.decrypted_file_exists?)
          @prompt.error "The decrypted file #{avault.decrypted_file} does not exist. Please decrypt the vault first."
          return false
        end

        if(!@force)
          if(avault.decrypted_file_outdated?)
            @prompt.warn "The decrypted file #{avault.decrypted_file} is outdated, not encrypting (Specify --force to override)"
            return false
          end
        end

        @shell.run(avault.encrypt_command)
      end

    end
  end
end
