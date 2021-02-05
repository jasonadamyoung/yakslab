require_relative 'sub_command_base'
require_relative 'subtest/subsubtest'

module YaksCLI
  class Subtest < SubCommandBase

    desc "testme", "Test command"
    def testme
      puts "Subtest::testme"
    end

    desc "subsubtest", "Execute Subsubtest commands"
    subcommand "subsubtest", YaksCLI::Subsubtest


  end
end