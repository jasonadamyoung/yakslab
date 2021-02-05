module LabTools
  module Ansible
    class Playbook
      def initialize(playbook_file:, playbook_options: [], options: {})
        if(playbook_file.nil?)
          raise LabToolsError, "A playbook name is required"
        end

        # convenience .yml adder
        extension = File.extname(playbook_file)
        if(extension == '')
          @playbook_file = playbook_file + ".yml"
        else
          @playbook_file = playbook_file
        end

        if(!File.exists?(@playbook_file))
          raise LabToolsError, "No such file exists: #{@playbook_file}"
        end

        @playbook_options = playbook_options
        options.each do |key,value|
          case key.to_s
          when 'verbosity'
            @playbook_options << playbook_verbosity(value)
          when 'limit'
            @playbook_options << "--limit=#{value}"
          when 'tags'
            @playbook_options << "--tags=#{value}"
          when 'extra_vars'
            @playbook_options << "--extra-vars '#{value.to_json}'"
          end
        end

        @playbook_options.uniq.compact!
      end

      def playbook_verbosity(verbosity_value)
        if(verbosity_value == 0)
          nil
        elsif(verbosity_value.between?(1,4))
          '-' + 'v' * verbosity_value
        else
          nil
        end
      end

      def environment
        environment = {}
        environment["PYTHONWARNINGS"] = "ignore"
        if(@ignore_host_key)
          environment["ANSIBLE_HOST_KEY_CHECKING"] = "False"
        end
        environment
      end

      def command
        "ansible-playbook #{command_options}"
      end

      def command_options
        if(!@playbook_options.empty?)
          "#{@playbook_options.join(' ')} #{@playbook_file}"
        else
          "#{@playbook_file}"
        end
      end

    end
  end
end
