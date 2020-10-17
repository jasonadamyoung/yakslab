require 'kubeclient'

module LabTools
  module Kubernetes
    class Configuration

      def initialize(kubeconfig_directory:, data: nil, file: nil)
        @kubeconfig_directory = kubeconfig_directory
        if(file.nil? and data.nil?)
          raise LabToolsError, "Either a filename, or data string is required to initialize a Kubeconfig."
        end

        if(!file.nil?)
          @source = "file"
          @kubeconfig_file = file
          if(File.exists?(@kubeconfig_file))
            @kubeconfig = Kubeclient::Config.read(@kubeconfig_file)
            return self
          else
            raise LabToolsError, "The specified kubeconfig file: #{file} does not exist."
          end
        elsif(!data.nil?)
          @source = "data"
          @raw_data = data
          begin
            kubeconfig_data = YAML.safe_load(@raw_data.to_s, [Date, Time])
            @kubeconfig =  Kubeclient::Config.new(kubeconfig_data,nil)
            return self
          rescue
            raise LabToolsError, "Unable to parse the provided kubeconfig data as YAML."
          end
        end
      end

      def kubeclient_config
        @kubeconfig
      end


    end
  end
end
