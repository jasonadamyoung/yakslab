require 'kubeclient'

module LabTools
  module Kubernetes
    class Cluster

      def initialize(with_data: nil, with_file: nil)
        @configuration = Configuration.new(data: with_data, file: with_file)
        @kubeconfig = @configuration.kubeclient_config
      end

      def kubeconfig
        @kubeconfig
      end

      def api_endpoint
        context = kubeconfig.context
        context&.api_endpoint
      end

      def core_client
        if(@core_client.nil?)
          context = kubeconfig.context
          @core_client =  Kubeclient::Client.new("#{self.api_endpoint}/api",
                                                      "v1",
                                                      ssl_options: context.ssl_options,
                                                      auth_options: context.auth_options
                                                    )
        end
        @core_client
      end

      def rbac_client
        if(@rbac_client.nil?)
          context = kubeconfig.context
          @rbac_client =  Kubeclient::Client.new("#{self.api_endpoint}/apis/rbac.authorization.k8s.io",
                                                      "v1",
                                                      ssl_options: context.ssl_options,
                                                      auth_options: context.auth_options
                                                    )
        end
        @rbac_client
      end

      def server_version
        version_resource = core_client.create_rest_client('version')
        if(body = version_resource.get.body)
          JSON.parse(body)
        else
          nil
        end
      end
    end
  end
end