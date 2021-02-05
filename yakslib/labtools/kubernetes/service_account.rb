require 'kubeclient'
require 'jwt'
require 'openssl'

module LabTools
  module Kubernetes
    class ServiceAccount

      def initialize(cluster:, name:, namespace: 'kube-system')
        @cluster = cluster
        @name = name
        @namespace = namespace
        @sar = Kubeclient::Resource.new(metadata: {name: name, namespace: namespace})
      end

      def cluster
        @cluster
      end

      def get
        kubeclient = @cluster.core_client
        begin
          kubeclient.get_service_account(@sar.metadata.name, @sar.metadata.namespace)
        rescue ::Kubeclient::ResourceNotFoundError
          nil
        end
      end

      def exists?
        (sa = self.get) ? true : false
      end

      def is_cluster_admin?
        (crb = self.get_cluster_role_binding) ? true : false
      end

      def cluster_admin_account_exists?
        exists? and is_cluster_admin?
      end

      def create_cluster_admin_account
        if(!cluster_admin_account_exists?)
          if(sa = self.create)
            return sa if (crb = self.create_cluster_admin_role_binding)
          else
            nil
          end
        end
      end

      def create
        kubeclient = @cluster.core_client
        if(!(sa = self.get))
          kubeclient.create_service_account(@sar)
        else
          sa
        end
      end

      def get_cluster_role_binding
        kubeclient = @cluster.rbac_client
        begin
          kubeclient.get_cluster_role_binding(@sar.metadata.name)
        rescue Kubeclient::ResourceNotFoundError
          nil
        end
      end

      def create_cluster_admin_role_binding
        kubeclient = @cluster.rbac_client
        crb_resource = self.cluster_admin_resource_for_service_account
        kubeclient.update_cluster_role_binding(crb_resource)
      end

      def get_account_secret
        kubeclient = @cluster.core_client
        if(sa = self.get and token_name = sa&.secrets[0]&.name)
          begin
            kubeclient.get_secret(token_name, @sar.metadata.namespace).as_json
          rescue Kubeclient::ResourceNotFoundError
            nil
          end
        else
          nil
        end
      end

      def get_account_token_and_cert
        if(secret = self.get_account_secret)
          token_and_cert = {}
          token_and_cert[:token] = Base64.decode64(secret&.dig('data', 'token'))
          token_and_cert[:ca_cert] = Base64.decode64(secret&.dig('data', 'ca.crt'))
        end
        token_and_cert
      end

      def decoded_account_token_and_cert
        token_and_cert = get_account_token_and_cert
        decoded = {}
        decoded[:token] = JWT.decode(token_and_cert[:token],nil,false)
        decoded[:ca_cert] = OpenSSL::X509::Certificate.new(token_and_cert[:ca_cert])
        decoded
      end

      def cluster_admin_resource_for_service_account
        subjects = [{ kind: 'ServiceAccount', name: @sar.metadata.name, namespace: @sar.metadata.namespace }]
        role_ref = {
          apiGroup: 'rbac.authorization.k8s.io',
          kind: 'ClusterRole',
          name: 'cluster-admin'
        }

        Kubeclient::Resource.new({
          metadata: {name: @sar.metadata.name},
          roleRef: role_ref,
          subjects: subjects
        })
      end
    end
  end
end
