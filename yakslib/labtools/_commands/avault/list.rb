require_relative '../labcommand'

module LabCommand
  module Avault
    class List < LabCommand::Base
      def initialize(options: {})
        @options = options
      end

      def 🚀
        vaultfiles = LabTools::AnsibleVault.find_all_vault_files
        puts "Found #{vaultfiles.size} files ending in _vault.yml:"
        vaultfiles.each do |vf|
          puts "  #{vf}"
        end
      end
    end
  end
end
