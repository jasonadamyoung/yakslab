require 'labclient'

module LabTools
  module GitLab
    class ClusterIntegration
      attr_accessor :project_id, :group_id

      def initialize(service_account:, group: '', project: '', profile:)
        @service_account = service_account
        @profile = profile

        # validate LabClient configuration
        labclient_profiles = File.expand_path("~/.gitlab-labclient")
        if(!File.exists?(labclient_profiles))
          raise LabToolsError, "No LabClient Profiles configuration found, please create #{labclient_profiles}"
        end

        profile_data = JSON.parse(File.read(labclient_profiles))
        if(!(profile_data[@profile]))
          raise LabToolsError, "No GitLab profile settings found in #{labclient_profiles} for the specified profile: #{@profile}"
        end

        # initialize api client
        self.api_client

        if(group.blank? and project.blank?)
          raise LabToolsError, "A group or project must be specified. Instance-level clusters are not suppported "
        end

        if(!group.blank?)
          @scope = 'group'
          self.group_id = group.strip
        elsif(!project.blank?)
          @scope = 'project'
          self.project_id = project.strip
        end
      end

      def service_account
        @service_account
      end

      def scope
        @scope
      end

      def api_client
        if(@api_client.nil?)
          @api_client = LabClient::Client.new(profile: @profile)
        end
        @api_client
      end

      def api_url
        @api_client.settings[:url]
      end

      def group_or_project_name
        case @scope
        when 'group'
          group.name
        when 'project'
          project.name
        end
      end

      def group_or_project_url
        case @scope
        when 'group'
          group.web_url
        when 'project'
          project.web_url
        end
      end

      def project
        return nil if (self.scope != 'project')
        if(@project.blank?)
          project = self.api_client.projects.show(self.project_id)
          if(project.success?)
            @project = project
          else
            raise LabToolsError, "Project request returned #{project.code}"
          end
        end
        @project
      end

      def group
        return nil if (self.scope != 'group')
        if(@group.blank?)
          group = self.api_client.groups.show(self.group_id)
          if(group.success?)
            @group = group
          else
            raise LabToolsError, "Group request returned #{group.code}"
          end
        end
        @group
      end

      def clusters
        case self.scope
        when 'project'
          self.project.clusters
        when 'group'
          self.group.clusters
        else
          nil
        end
      end

      def clusters_information
        clusters_info = []
        clusters.each do |cluster|
          info = {}
          info["id"]         = cluster.id
          info["name"]       = cluster.name
          info["created_at"] = cluster.created_at.to_formatted_s(:rfc822)
          info["type"]       = cluster.platform_type
          clusters_info << info
        end
        clusters_info
      end

      def get(cluster_name:)
        if(@integration.nil?)
          clusters.each do |cluster|
            if(cluster.name == cluster_name)
              @integration = cluster
            end
          end
        end
        @integration
      end

      def cluster_information(cluster_name:)
        info = {}
        if(cluster = get(cluster_name: cluster_name))
          info["id"]         = cluster.id
          info["name"]       = cluster.name
          info["created_at"] = cluster.created_at.to_formatted_s(:rfc822)
          info["type"]       = cluster.platform_type
        end
        info
      end

      def exists?(cluster_name:)
        (ci = self.get(cluster_name: cluster_name)) ? true : false
      end

      def create(cluster_name:,cluster_options: {})
        create_params                         = {}
        create_params[:name]                  = cluster_name
        if(!(token_and_cert = self.service_account.get_account_token_and_cert))
          raise LabToolsError, "Unable to get service account token and ca_cert for cluster"
        end

        create_params[:domain]                = cluster_options[:domain]
        create_params[:management_project_id] = cluster_options[:management_project_id]
        create_params[:enabled]               = cluster_options[:enabled] || true
        create_params[:managed]               = cluster_options[:managed] || true
        create_params[:environment_scope]     = cluster_options[:environment_scope]

        kubernetes_attributes                      = {}
        kubernetes_attributes[:api_url]            = self.service_account.cluster.api_endpoint
        kubernetes_attributes[:token]              = token_and_cert[:token]
        kubernetes_attributes[:ca_cert]            = token_and_cert[:ca_cert]
        if(is_project_scope?)
          kubernetes_attributes[:namespace]          = cluster_options[:namespace]
        end
        kubernetes_attributes[:authorization_type] = cluster_options[:authorization_type] || "rbac"
        create_params[:platform_kubernetes_attributes] = kubernetes_attributes

        case self.scope
        when 'project'
          self.api_client.projects.clusters.add(self.project.id,create_params).success?
        when 'group'
          self.api_client.groups.clusters.add(self.group_id,create_params).success?
        else
          false
        end
      end

      def update(cluster_name:,cluster_options: {})
        if(!(current_cluster = self.get(cluster_name: cluster_name)))
          raise LabToolsError, "Unable to get existing cluster integration to update cluster"
        end
        update_params                         = {}

        if(!(token_and_cert = self.service_account.get_account_token_and_cert))
          raise LabToolsError, "Unable to get service account token and ca_cert for cluster"
        end

        update_params[:name]                  = cluster_options[:name] || cluster_name
        update_params[:domain]                = cluster_options[:domain]
        update_params[:management_project_id] = cluster_options[:management_project_id]
        update_params[:environment_scope]     = cluster_options[:environment_scope] || '*'

        # byproduct of setting them this way is they will always update
        kubernetes_attributes                      = {}
        kubernetes_attributes[:api_url]            = self.service_account.cluster.api_endpoint
        kubernetes_attributes[:token]              = token_and_cert[:token]
        kubernetes_attributes[:ca_cert]            = token_and_cert[:ca_cert]
        if(is_project_scope?)
          kubernetes_attributes[:namespace]          = cluster_options[:namespace]
        end
        update_params[:platform_kubernetes_attributes] = kubernetes_attributes

        case self.scope
        when 'project'
          result = self.api_client.projects.clusters.update(self.project.id,current_cluster.id,update_params)
          result.success?
        when 'group'
          result = self.api_client.groups.clusters.update(self.group_id,current_cluster.id,update_params)
          result.success?
        else
          false
        end
      end

      def delete(cluster_name: )
        if(!(current_cluster = self.get(cluster_name: cluster_name)))
          raise LabToolsError, "Unable to get existing cluster integration to delete cluster"
        end

        case self.scope
        when 'project'
          result = self.api_client.projects.clusters.delete(self.project.id,current_cluster.id)
          # delete returns nil on success - and a TyphoeusResponse on failure
          result.nil?
        when 'group'
          result = self.api_client.groups.clusters.delete(self.group_id,current_cluster.id)
          # delete returns nil on success - and a TyphoeusResponse on failure
          result.nil?
        else
          false
        end
      end

      def is_project_scope?
        self.scope == 'project'
      end

      def is_group_scope?
        self.scope == 'group'
      end

    end
  end
end