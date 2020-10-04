require 'inifile'

module Yaks
  class AnsibleVault

    def initialize(vault_file:, options: {})
      @vault_file = vault_file
      @ansible_config = IniFile.load('./ansible.cfg')
      if(!(@vault_key_file = @ansible_config['defaults']['vault_password_file']))
        raise YaksError, "The ansible.cfg file is missing a vault_password_file setting"
      end

      if(!File.exists?(@vault_key_file))
        raise YaksError, "The vault password file is missing! #{@vault_key_file}"
      end

      if(@vault_file.nil?)
        raise YaksError, "A specified vault file to encrypt/decrypt is required"
      end

      if(!File.exists?(@vault_file))
        raise YaksError, "No such file exists: #{@vault_file}"
      end

      @quiet = options[:quiet].nil? ? false : options[:quiet]
      @dryrun = options[:dryrun].nil? ? false : options[:dryrun]
      @force = options[:force].nil? ? false : options[:force]
    end

    def decrypted_file
      "#{@vault_file}.decrypted"
    end

    def decrypted_file_exists?
      File.exists?(decrypted_file)
    end

    def decrypted_file_outdated?
      (File.mtime(decrypted_file) < File.mtime(@vault_file))
    end

    def encrypt_command
      "ansible-vault encrypt #{decrypted_file} --output=#{@vault_file}"
    end

    def decrypted_file_newer?
      decrypted_file_exists? and (File.mtime(decrypted_file) > File.mtime(@vault_file))
    end

    def decrypt_command
      "ansible-vault decrypt #{@vault_file} --output=#{decrypted_file}"
    end

    def self.find_all_vault_files
      Dir.glob('./**/*_vault.yml')
    end



  end
end
