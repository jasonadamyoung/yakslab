require 'yaml'
require 'json'
require_relative "utils.rb"
require_relative "ip_allocator.rb"
require_relative "generic_host.rb"
require_relative "gitlab_hosts.rb"
require_relative "k3s_cluster.rb"

module VagrantHosts
  class Maker
    DEFAULTS_FILE = "vagrant-hosts-defaults.yml"
    HOST_FILE = "vagrant-hosts.yml"

    def initialize(configuration_root:, host_file: HOST_FILE)
      @host_file = host_file
      @actual_host_file = File.realpath(host_file)
      @hosts_json = File.join(File.dirname(@host_file),"#{File.basename(@actual_host_file)}.json")
      @groups_yaml = File.join(File.dirname(@host_file),"#{File.basename(@actual_host_file)}_groups.yml")
      @configuration_root = configuration_root
      @defaults_data = YAML.load_file(File.join(@configuration_root,DEFAULTS_FILE))
      @defaults = @defaults_data["defaults"]
      @host_file_data = YAML.load_file(@host_file)
    end

    def get_hosts_and_groups
      returnhosts = []
      returngroups = {}
      @host_file_data['hosts'].each do |hosts_entry|
        (hosts,groups) = process_hosts_entry(hosts_entry: hosts_entry)
        returnhosts += hosts
        returngroups.merge!(groups)
      end

      [returnhosts,returngroups]
    end

    def process_hosts_entry(hosts_entry:, other_hosts: [])
      (service,values) = hosts_entry.first

      # provisioner settings
      case service
      when 'gitlab'
        # standalone gitlab host
        @gitlab_hosts = GitLabHosts.new(configuration_root: @configuration_root, values: values, defaults: @defaults)
        @gitlab_hosts.host_and_group_configuration
      when 'k3s_cluster'
        @k3s_cluster = K3sCluster.new(configuration_root: @configuration_root, values: values, defaults: @defaults)
        @k3s_cluster.host_and_group_configuration
      when 'single'
        @generic_host = GenericHost.new(configuration_root: @configuration_root, values: values, defaults: @defaults)
        @generic_host.host_and_group_configuration
      end
    end
  end
end