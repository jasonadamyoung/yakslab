require_relative 'sub_command_base'

module YaksCLI
  class K3s < SubCommandBase

    desc "download", "Download k3s Release"
    method_option :force, :type => :boolean, :default => false, :desc => "Force download even if target file(s) exist"
    def download(release_version)
      require_relative '../labtools/_commands/k3s/download'
      command_options = options.merge(cache_directory: Yaks.settings.k3s_cache_directory)
      LabCommand::K3s::Download.new(version: release_version, options: command_options).🚀
    end

    desc "latest", "Latest K3s Release Information"
    def latest
      require_relative '../labtools/_commands/k3s/latest'
      LabCommand::K3s::Latest.new(options: options).🚀
    end

    desc "dump DUMPFILE", "Dump K3s Release Information to a yaml file"
    method_option :quiet, :type => :boolean, :default => false, :desc => "Don't show progress spinner"
    def dump(dump_file)
      require_relative '../labtools/_commands/k3s/dump'
      LabCommand::K3s::Dump.new(dump_file: dump_file, options: options).🚀
    end

    desc "version", "Query Kubernetes Version information for the specified K3s host"
    method_option :host, :required => true, :type => :string, :desc => "Remote K3s host"
    def version
      require_relative '../labtools/_commands/k3s/version'
      LabCommand::K3s::Version.new(host: options[:host], options: options).🚀
    end

  end
end