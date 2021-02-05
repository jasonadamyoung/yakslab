require_relative '../sub_command_base'

module YaksCLI
  class Subsubtest < SubCommandBase

    desc "subtestme", "Test command"
    def subtestme
      puts "Subsubtest::subtestme"
    end

  end
end