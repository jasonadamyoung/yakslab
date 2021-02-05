require 'tty-spinner'

module LabCommand
  class Base

    def 🚀(*)
      raise(
        NotImplementedError,
        "#{self.class}##{__method__} must be implemented"
      )
    end

    def command(**options)
      require 'tty-command'
      TTY::Command.new(options)
    end

    def logger(**options)
      require 'tty-logger'
      TTY::Logger.new(options)
    end

    def prompt(**options)
      require 'tty-prompt'
      TTY::Prompt.new(options)
    end

  end
end
