require_relative 'sub_command_base'

module YaksCLI
  class Releases < SubCommandBase

    desc "k3d", "Print out the latest k3d release from GitHub"
    method_option :updateroleyaml, :type => :string, :default => nil, :desc => "Updates `k3d_version` field in the specified yaml file (e.g. an Ansible role)"
    def k3d
      require_relative '../labtools/_commands/releases/k3d'
      LabCommand::Releases::K3d.new(options: options).🚀
    end

    desc "k3s", "Latest K3s Release Information"
    def k3s
      require_relative '../labtools/_commands/releases/k3s'
      LabCommand::Releases::K3s.new(options: options).🚀
    end

    desc "gitlab VERSION", "Print out the latest GitLab release information for VERSION (grouped,latest,backports, or a version number. default: backports)"
    method_option :output, :type => :string, :default => 'default', :desc => "Output format - accepted options are 'default': (filtered list), 'json'/'yaml': (filtered json/yaml), or 'raw_json'/'raw_yaml': raw GitLab API json/yaml"
    method_option :edition, :type => :string, :default => 'EE', :desc => "Edition (EE or CE)"
    def gitlab(version='default')
      require_relative '../labtools/_commands/releases/gitlab'
      LabCommand::Releases::GitLab.new(version: version, options: options).🚀
    end

    desc "dump PROJECT DUMPFILE", "Dump [PROJECT] Release Information to a yaml or json file"
    method_option :quiet, :type => :boolean, :default => false, :desc => "Don't show progress spinner"
    method_option :update_cache, :type => :boolean, :default => false, :desc => "Update cache information"
    def dump(project,dump_file)
      if(project == 'gitlab')
        require_relative '../labtools/_commands/releases/gitlab_dump'
        LabCommand::Releases::GitLabDump.new(dump_file: dump_file, options: options).🚀
      elsif(project == 'k3s')
        require_relative '../labtools/_commands/releases/k3s_dump'
        LabCommand::Releases::K3sDump.new(dump_file: dump_file, options: options).🚀
      else
        puts "Project #{options[:project]} not yet supported"
      end
    end

  end
end