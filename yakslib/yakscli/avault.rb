require_relative 'sub_command_base'

module YaksCLI
  class Avault < SubCommandBase
    class_option :verbosity, :type => :numeric, :default => 0, :desc => "ansible-vault verbosity (0=none,1=-v,2=-vv,3=-vvv,4=-vvvv)"

    desc "list", "List known vault files"
    def list
      require_relative '../commands/avault/list'
      LabCommand::Avault::List.new(options: options).🚀
    end

    desc "encrypt VAULTFILE", "Use ansible-vault to encrypt a decrypted vault file and save it as VAULTFILE (specify all to encrypt all found vault files)"
    method_option :force, :type => :boolean, :default => false, :desc => "Force encryption even if the encrypted file is newer"
    def encrypt(vault_file)
      require_relative '../commands/avault/encrypt'
      LabCommand::Avault::Encrypt.new(vault_file: vault_file, options: options).🚀
    end

    desc "decrypt VAULTFILE", "Use ansible-vault to decrypt an encrypted vault file and save it as VAULTFILE (specify all to decrypt all found vault files)"
    method_option :force, :type => :boolean, :default => false, :desc => "Force decryption even if the decrypted file is newer"
    def decrypt(vault_file)
      require_relative '../commands/avault/decrypt'
      LabCommand::Avault::Decrypt.new(vault_file: vault_file, options: options).🚀
    end
  end
end