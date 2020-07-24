module Rap
    class Dehydrated

      def initialize(options = {})
        @quiet = options[:quiet].nil? ? false : options[:quiet]
        @dryrun = options[:dryrun].nil? ? false : options[:dryrun]
        @forceit = options[:force].nil? ? false : options[:force]
      end

      def environment
        environment = {}
        environment
      end

      def dehydrated_command
        "cd certificates && ./dehydrated"
      end

      def renew!
        if(@forceit)
          runcommand = "#{self.dehydrated_command} --cron --force"
        else
          runcommand = "#{self.dehydrated_command} --cron"
        end
        self.go!(runcommand)
      end

      def cleanup
        runcommand = "#{self.dehydrated_command} --cleanup"
        self.go!(runcommand)
      end

      def info
        runcommand = "#{self.dehydrated_command} --env"
        self.go!(runcommand)
      end

      def go!(runcommand)
        if(@dryrun)
          puts("[DRY RUN] Would run: #{runcommand}")
        else
          puts("Running: #{runcommand}") if !@quiet
          system(self.environment, runcommand)
        end
      end

    end
  end
