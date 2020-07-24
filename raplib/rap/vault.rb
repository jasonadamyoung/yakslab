require 'inifile'

module Rap
  class Vault

    def initialize(options = {})

      @vault_key_file = self.class.ansible_vault_key_file
      if(@vault_key_file.nil?)
        raise RapError, "The ansible.cfg file is missing a vault_password_file setting"
      end

      if(!File.exists?(@vault_key_file))
        raise RapError, "The vault password file is missing! #{@vault_key_file}"
      end

      if(options[:vault].nil?)
        raise RapError, "A specified vault file to encrypt/decrypt is required"
      end

      @vault_file = options[:vault]

      if(!File.exists?(@vault_file))
        raise RapError, "No such file exists: #{@vault_file}"
      end

      @quiet = options[:quiet].nil? ? false : options[:quiet]
      @dryrun = options[:dryrun].nil? ? false : options[:dryrun]
      @force = options[:force].nil? ? false : options[:force]
    end

    def environment
      {}
    end

    def encrypt!
      decrypted_file = "#{@vault_file}.decrypted"
      if(!File.exists?(decrypted_file))
        puts "Error: The decrypted file #{decrypted_file} for #{@vault_file} does not exist. Please decrypt the vault first."
        return false
      end

      # modified time check
      if(!@force)
        if(File.mtime(decrypted_file) < File.mtime(@vault_file))
          puts "Warning: The decrypted file #{decrypted_file} is older than #{@vault_file}, not encrypting. Specify the force option to override"
          return false
        end
      end

      vault_thing_command = "ansible-vault encrypt #{decrypted_file} --output=#{@vault_file}"
      self._do_vault_thing(vault_thing_command)
    end

    def decrypt!
      decrypted_file = "#{@vault_file}.decrypted"
      # modified time check

      if(File.exists?(decrypted_file) and !@force)
        if(File.mtime(decrypted_file) > File.mtime(@vault_file))
          puts "Warning: The decrypted file #{decrypted_file} is newer than #{@vault_file}, not decrypting. Specify the force option to override"
          return false
        end
      end

      vault_thing_command = "ansible-vault decrypt #{@vault_file} --output=#{decrypted_file}"
      self._do_vault_thing(vault_thing_command)
    end

    def _do_vault_thing(vault_thing_command)
      if(@dryrun)
        puts("[DRY RUN] Would run: #{vault_thing_command}")
      else
        puts("Running: #{vault_thing_command}") if !@quiet
        system(self.environment, vault_thing_command)
      end
    end

    def self.find_all_vault_files
      files = []
      Dir.glob('./**/*_vault.yml').each do |f|
        files << f
      end
      return files
    end

    def self.ansible_vault_key_file
      ansible_config = IniFile.load('./ansible.cfg')
      if(ansible_config['defaults']['vault_password_file'])
        ansible_config['defaults']['vault_password_file']
      else
        nil
      end
    end
  end
end
