module Rap
  class Aplay

    def initialize(options = {})

      @ignore_host_key = options[:ignore_host_key].nil? ? false : options[:ignore_host_key]
      if(options[:playbook].nil?)
        raise RapError, "A playbook name is required"
      end

      # convenience .yml adder
      extension = File.extname(options[:playbook])
      if(extension == '')
        @playbook_file = options[:playbook] + ".yml"
      else
        @playbook_file = options[:playbook]
      end

      if(!File.exists?(@playbook_file))
        raise RapError, "No such file exists: #{@playbook_file}"
      end

      @quiet = options[:quiet].nil? ? false : options[:quiet]
      @dryrun = options[:dryrun].nil? ? false : options[:dryrun]
      @playbook_options = options[:playbook_options].nil? ? [] : options[:playbook_options]
    end

    def environment
      environment = {}
      environment["PYTHONWARNINGS"] = "ignore"
      if(@ignore_host_key)
        environment["ANSIBLE_HOST_KEY_CHECKING"] = "False"
      end
      environment
    end

    def playbook_command
      "ansible-playbook"
    end

    def go!
      if(!@playbook_options.empty?)
        runcommand = "#{self.playbook_command} #{@playbook_options.join(' ')} #{@playbook_file}"
      else
        runcommand = "#{self.playbook_command} #{@playbook_file}"
      end
      if(@dryrun)
        puts("[DRY RUN] Would run: #{runcommand}")
      else
        puts("Running: #{runcommand}") if !@quiet
        system(self.environment, runcommand)
      end
    end

  end
end
