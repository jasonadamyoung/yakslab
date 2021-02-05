require 'octokit'
require 'down'

module LabTools
  module Releases
    module Tools

      def is_gitlab?
        @release_data_source == 'gitlab'
      end

      def github_client
        if(@github_client.nil?)
          @github_client = Octokit::Client.new
          @github_client.auto_paginate = true
        end
        @github_client
      end

      def gitlab_client
        if(@gitlab_client.nil?)
          @gitlab_client = LabClient::Client.new(url: @gitlab_instance_url, token: @gitlab_token)
        end
        @gitlab_client
      end

      def github_releases(release_project:)
        github_client.list_releases(release_project)
      end

      def github_latest_release(release_project:)
        github_client.latest_release(release_project)
      end

      def gitlab_releases(release_project:)
        gitlab_client.projects.releases.list(release_project)
      end


      def gitlab_tags(release_project:, options: {})
        gitlab_client.tags.list(release_project, options)
      end

      def gitlab_project(release_project:)
        if(@gitlab_project.nil?)
          api_result = gitlab_client.projects.show(release_project)
          raise LabToolsError, "GitLab project request returned #{api_result.code}" if(!api_result.success?)
          @gitlab_project = api_result
        end
        @gitlab_project
      end

      def cache_api_result_data(data:, filename:)
        File.open(filename, 'wb') {|f| f.write(Marshal.dump(data))}
      end

      def load_cached_api_result_data(filename:)
        Marshal.load(File.binread(filename))
      end

      def get_apicache_file(label:)
        if(@api_cache_files.nil?)
          @api_cache_files = {}
        end

        if(@api_cache_files[label].nil?)
          @api_cache_files = {} if @api_cache_files.nil?
          @api_cache_files[label] = File.expand_path("#{@api_cache_dir}/#{self.class.to_s.split('::').last.downcase}_#{label}.cache")
        end
        @api_cache_files[label]
      end

      def download_url_for_github_release_and_asset(github_release:, asset_name:)
        github_release[:assets].each do |asset|
          if(asset[:name] == asset_name)
            return asset[:browser_download_url]
          end
        end
        nil
      end

    end
  end
end