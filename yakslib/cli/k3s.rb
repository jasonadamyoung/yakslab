require_relative 'sub_command_base'

module YaksCLI
  class K3s < SubCommandBase
    desc "download", "Download k3s Release"
    method_option :force, :type => :boolean, :default => false, :desc => "Force download even if target file(s) exist"
    def download(release_version)
      require_relative '../commands/k3s/download'
      Yaks::Commands::K3s::Download.new(version: release_version, options: options).🚀
    end
    desc "latest", "Latest K3s Release Information"
    def latest
      require_relative '../commands/k3s/latest'
      Yaks::Commands::K3s::Latest.new(options: options).🚀
    end

  end
end