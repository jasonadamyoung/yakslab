require_relative '../../command'

module Yaks
  module Commands
    module Avault
      class Decrypt < Yaks::Command
        def initialize(vault_file:, options: {})
          @vault_file = vault_file
          @options = options
          @force = options[:force].nil? ? false : options[:force]
          @logger = logger
          @shell = command(dry_run: @options[:dry_run], uuid: false, printer: :quiet)
        end

        def 🚀
          if(@vault_file == 'all')
            vaultfiles = Yaks::AnsibleVault.find_all_vault_files
          else
            vaultfiles = [@vault_file]
          end
          vaultfiles.each do |vf|
            decrypt_vault(vault_file: vf)
          end
        end

        def decrypt_vault(vault_file: )
          puts "Decrypting #{vault_file}"
          avault = Yaks::AnsibleVault.new(vault_file: vault_file, options: @options)

          if(!@force)
            if(avault.decrypted_file_newer?)
              @logger.warn "The decrypted file #{avault.decrypted_file} is newer, not decrypting (Specify --force to override)"
              return false
            end
          end

          @shell.run(avault.decrypt_command)
        end


      end
    end
  end
end
