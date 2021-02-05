require 'net/ssh'
require 'net/scp'
require 'yaml'

module LabTools
  module K3d
    class RemoteTools
      TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y']
      FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N']


      def initialize(host:)
        @host = host
      end

      def clusters(force_update: false)
        if(@clusters.nil? or force_update)
          @clusters = []
          Net::SSH.start(@host) do |ssh|
            command = "/usr/local/bin/k3d cluster list"
            @raw_list_output = ssh.exec!(command)
            @list_status = @raw_list_output.exitstatus
          end

          # ignore the header line
          list_output = @raw_list_output.split("\n").drop(1)
          list_output.each do |cluster_info|
            (name,servers,agents,loadbalancer) = cluster_info.split("\s")
            ci = OpenStruct.new
            ci.name = name
            (ci.running_servers,ci.total_servers) = servers.split('/').map{|i| i.to_i}
            (ci.running_agents,ci.total_agents) = agents.split('/').map{|i| i.to_i}
            ci.running = (ci.running_servers > 0 and ci.running_agents > 0)
            ci.has_loadbalancer = TRUE_VALUES.include?(loadbalancer)
            @clusters << ci
          end
        end
        @clusters
      end

      def cluster_names
        @clusters.map(&:name)
      end

      def get_cluster(cluster_name)
        clusters.each do |cluster|
          return cluster if cluster.name == cluster_name
        end
        nil
      end

      def start_cluster(cluster_name)
        if(!cluster = get_cluster(cluster_name))
          raise LabToolsError, "The specified cluster: #{cluster_name} does not exist on the host: #{@host}"
        end

        return true if cluster.running

        Net::SSH.start(@host) do |ssh|
          command = "/usr/local/bin/k3d cluster start #{cluster_name}"
          @raw_start_output = ssh.exec!(command)
          @start_status = @raw_start_output.exitstatus
        end

        (@start_status == 0)
      end

      def stop_cluster(cluster_name)
        if(!cluster = get_cluster(cluster_name))
          raise LabToolsError, "The specified cluster: #{cluster_name} does not exist on the host: #{@host}"
        end

        return true if !cluster.running

        Net::SSH.start(@host) do |ssh|
          command = "/usr/local/bin/k3d cluster stop #{cluster_name}"
          @raw_stop_output = ssh.exec!(command)
          @stop_status = @raw_stop_output.exitstatus
        end

        (@stop_status == 0)
      end

      def kubeconfig_data(cluster_name, force_update: false)
        if(@kubeconfigs.nil? or @kubeconfigs[cluster_name].nil? or force_update)
           @kubeconfigs = {} if @kubeconfigs.nil?
          if(!cluster = get_cluster(cluster_name))
            raise LabToolsError, "The specified cluster: #{cluster_name} does not exist on the host: #{@host}"
          end

          Net::SSH.start(@host) do |ssh|
            command = "/usr/local/bin/k3d kubeconfig get #{cluster_name}"
            @raw_kubeconfig_output = ssh.exec!(command)
            @kubeconfig_status = @raw_kubeconfig_output.exitstatus
          end

          if(@kubeconfig_status == 0)
            @kubeconfigs[cluster_name] = @raw_kubeconfig_output.gsub('0.0.0.0',@host).to_s
          else
            @kubeconfigs[cluster_name] = nil
          end
        end
        @kubeconfigs[cluster_name]
      end

    end
  end
end