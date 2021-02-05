require_relative "./utils.rb"
require_relative "./ip_allocator.rb"

module VagrantHosts
  class GitLabHosts
    GITLAB_VERSIONS_CACHE = "cached_gitlab_tag_info.yml"
    GITLAB_USE_FOCAL = "13.2.0"
    BIONIC_BOX = "bento/ubuntu-18.04"
    FOCAL_BOX  = "bento/ubuntu-20.04"
    GITLAB_ANSIBLE_PLAYBOOK   = "provisioning/gitlab.yml"
    ALLOWED_HOST_ROLES = ['app','gitaly']

    def initialize(configuration_root:, values:, defaults:)
      @configuration_root = configuration_root
      @gitlab_versions_cache = File.join(@configuration_root,GITLAB_VERSIONS_CACHE)
      @values = values
      @defaults = defaults
      @utils = Utils.new(defaults: defaults)
      @ip_allocator = IPAllocator.new(configuration_root: @configuration_root)
      @host_groups = parse_values_for_host_groups
    end

    def parse_values_for_host_groups
      # parse the values to set up the primary app server and host list
      return_host_groups = {}
      case @values.class.to_s
      when 'String'
        # standalone host, @values is version
        version_string = @values
        name = @utils.box_name_string(base_name: 'gitlab', version_string: version_string)
        return_host_groups['app'] = [{'version' => version_string, 'name' => name}]
      when 'Hash'
        # default to "latest" if there's no version present
        version_string = @values['version'] || 'latest'
        if(!@values['hosts'])
          # no lists of hosts - so it's standalone with values
          # default to "gitlab" if there's no name
          name = @values['name'] || @utils.box_name_string(base_name: 'gitlab', version_string: version_string)
          host_values = @values.merge({'version' => version_string, 'name' => name})
          return_host_groups['app'] = [host_values]
        else
          # there's a host list, reject a global name, but treat the rest of the values as a default
          default_host_values = @values.reject{|key,value| ['name','hosts'].include?(key)}.merge({'version' => version_string})
          return_host_groups = parse_host_list(hosts: @values['hosts'], host_defaults: default_host_values)
        end
      else
        raise VagrantHosts::MakerError, "The gitlab hosts entry is in an unexpected format, class: #{@values.class.to_s}"
      end
      return_host_groups
    end

    def parse_host_list(hosts:, host_defaults: {})
      return_host_groups = {}
      ALLOWED_HOST_ROLES.each do |role|
        if(hosts.keys.include?(role))
          return_host_groups[role] = []
          role_values = hosts[role] || {}
          total_host_count = role_values['count'] || 1
          (1..total_host_count).each do |host_counter|
            host_values = {}
            host_values.merge!(host_defaults)
            host_values.merge!(role_values)
            base_name = host_values['name_label'] ? "gitlab-#{host_values['name_label']}-#{role}" : "gitlab-#{role}"
            host_name_count = (total_host_count > 1) ? host_counter : nil
            host_name = @utils.box_name_string(base_name: base_name, version_string: host_values['version'], count: host_name_count)
            host_values.merge!({'name' => host_name})
            return_host_groups[role] << host_values
          end
        end
      end
      return_host_groups
    end

    def get_app_roles
      'all'
    end

    def gitlab_external_url
      if(!@gitlab_external_url)
        if(@gitlab_app_primary)
          @gitlab_external_url = @gitlab_app_primary['provisioner_settings']['gitlab_external_url']
        end
      end
      @gitlab_external_url
    end

    def gitlab_app_primary_name
      if(!@gitlab_app_primary_name)
        if(@gitlab_app_primary)
          @gitlab_app_primary_name = @gitlab_app_primary['box_settings']['name']
        end
      end
      @gitlab_app_primary_name
    end

    def host_name(host_settings)
      host_settings['box_settings']['name']
    end

    def has_external_gitaly?
      @host_groups.keys.include?('gitaly') and @host_groups['gitaly'].size >= 1
    end

    def omnibus_role_name_for_role(role)
      case role
      when 'gitaly'
        'gitaly'
      else
        role
      end
    end

    def host_and_group_configuration
      gitlab_hosts = []
      gitlab_groups = {}
      app_hosts = @host_groups['app'].dup

      # make primary app host
      primary_app_host_values = app_hosts.shift
      @app_server_roles = get_app_roles
      @gitlab_app_primary = make_host_settings(host_values: primary_app_host_values, roles: @app_server_roles)
      gitlab_hosts << @gitlab_app_primary
      gitlab_groups['gitlab'] = [host_name(@gitlab_app_primary)]
      gitlab_groups['gitlab_app'] = [host_name(@gitlab_app_primary)]
      gitlab_groups['gitlab_app_primary'] = [host_name(@gitlab_app_primary)]

      # other app hosts, if present
      app_hosts.each do |host_values|
        host_settings = make_host_settings(host_values: host_values, roles: @app_server_roles)
        gitlab_hosts << host_settings
        gitlab_groups['gitlab'] << host_name(host_settings)
        gitlab_groups['gitlab_app'] << host_name(host_settings)
      end

      # all other hosts
      host_groups = @host_groups.keys.reject{|role| role == 'app'}
      host_groups.each do |role|
        gitlab_groups["gitlab_#{role}"] ||= []
        @host_groups[role].each do |host_values|
          host_settings = make_host_settings(host_values: host_values, roles: omnibus_role_name_for_role(role))
          gitlab_hosts << host_settings
          gitlab_groups['gitlab'] << host_name(host_settings)
          gitlab_groups["gitlab_#{role}"] << host_name(host_settings)
        end
      end

      [gitlab_hosts, gitlab_groups]
    end

    def make_host_settings(host_values:, roles:)
      box_settings = {}
      provisioner_settings = {}
      ansible_settings = {}

      gitlab_version = get_gitlab_version(version: host_values["version"])
      box_settings["name"] = host_values["name"]
      box_settings["box"] = host_values['box'] || gitlab_box_setting(gitlab_version: gitlab_version)
      ["network", "memory", "cpu"].each do |setting|
        box_settings[setting] = host_values[setting] || @defaults[setting]
      end
      box_settings["ip_address"] = @ip_allocator.get_available_ip_address(host_name: box_settings["name"])

      # provisioner settings

      provisioner_settings['gitlab_external_url']    = gitlab_external_url || "http://#{box_settings['name']}"
      provisioner_settings['gitlab_app_primary']     = gitlab_app_primary_name  || box_settings['name']
      provisioner_settings['gitlab_ip_address']      = box_settings["ip_address"]
      provisioner_settings['gitlab_version']         = gitlab_version
      provisioner_settings['gitlab_edition']         = 'ee' # hardcoded to ee at the moment
      provisioner_settings['gitlab_external_gitaly'] = has_external_gitaly?
      provisioner_settings['gitlab_roles']           = roles

      merge_settings = host_values["provisioner_settings"] || {}
      provisioner_settings.merge!(merge_settings)

      ansible_settings.merge!(@defaults["ansible"])
      ansible_settings['playbook'] = GITLAB_ANSIBLE_PLAYBOOK
      merge_settings = host_values["ansible_settings"] || {}
      ansible_settings.merge!(merge_settings)

      {"box_settings" => box_settings, "provisioner_settings" => provisioner_settings, "ansible_settings" => ansible_settings}
    end



    def get_gitlab_version(version:)
      # TODO strip the -ce off if present

      if(!File.exists?(@gitlab_versions_cache))
        raise VagrantHosts::MakerError, "Please create the GitLab version cache file: #{@gitlab_versions_cache}"
      end
      gitlab_versions =  YAML.load_file(@gitlab_versions_cache)

      if(version == 'latest')
        gitlab_version = gitlab_versions["latest"]
        gitlab_version["version"]
      else
        version_number = Gem::Version.new(version)
        (major,minor,patch) = version_number.segments
        major_key = major.to_s
        if(!gitlab_versions.keys.include?(major_key))
          raise VagrantHosts::MakerError, "Invalid GitLab major version specified in #{version}"
        end

        if(minor.nil?)
          gitlab_version = gitlab_versions[major_key]["latest"]
          gitlab_version["version"]
        else
          major_minor_key = "#{major}.#{minor}"
          if(!gitlab_versions[major_key].keys.include?(major_minor_key))
            raise VagrantHosts::MakerError, "Invalid GitLab minor version specified in #{version}"
          end

          if(patch.nil?)
            gitlab_version = gitlab_versions[major_key][major_minor_key]["latest"]
            gitlab_version["version"]
          else
            specific_version = "#{major}.#{minor}.#{patch}"
            if(!gitlab_versions[major_key][major_minor_key].keys.include?(specific_version))
              raise VagrantHosts::MakerError, "The specified GitLab version: #{version} does not exist"
            end
            gitlab_version = gitlab_versions[major_key][major_minor_key][specific_version]
            gitlab_version["version"]
          end
        end
      end
    end

    def gitlab_box_setting(gitlab_version:)
      # use the ubuntu 20.04 box for GitLab versions > 13.2.0
      version_number = Gem::Version.new(gitlab_version)
      (version_number >= Gem::Version.new(GITLAB_USE_FOCAL)) ? FOCAL_BOX : BIONIC_BOX
    end

  end
end