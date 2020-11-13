require_relative 'sub_command_base'

module YaksCLI
  class Releases < SubCommandBase
    desc "k3d", "Print out the latest k3d release from GitHub"
    method_option :updateyaml, :type => :string, :default => nil, :desc => "If specified, updates `k3d_version` field in the yaml file (e.g. an Ansible role)"
    def k3d
      require_relative '../labtools/_commands/k3d/latest_release'
      LabCommand::K3d::LatestRelease.new(options: options).🚀
    end


  end
end