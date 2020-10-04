require_relative '../../command'

module Yaks
  module Commands
    module Avault
      class List < Yaks::Command
        def initialize(options: {})
          @options = options
        end

        def 🚀
          vaultfiles = Yaks::AnsibleVault.find_all_vault_files
          puts "Found #{vaultfiles.size} files ending in _vault.yml:"
          vaultfiles.each do |vf|
            puts "  #{vf}"
          end
        end
      end
    end
  end
end
