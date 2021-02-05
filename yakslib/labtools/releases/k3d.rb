require 'octokit'
require 'down'
require_relative 'tools'

module LabTools
  module Releases
    class K3d
      include LabTools::Releases::Tools
      K3D_VERSION_REGEX = %r{v(?<version>[\w|\.|-]+)}
      RELEASE_PROJECT = 'rancher/k3d'

      def initialize(options: {})
        @release_data_source = 'github'
        @api_cache_dir = options[:api_cache_dir] || './apicache'
        @ignore_prelease = options[:ignore_prelease] || true
        @release_project_id = RELEASE_PROJECT
        @architecture = options[:architecture] || 'amd64'
        @platform = options[:platform] || 'linux'
        @asset_name = "k3d-#{@platform}-#{@architecture}"
      end

      def releases(force_cache_update: false)
        if(@releases.nil?)
          @releases = []
          # check cache
          if(force_cache_update or release_cache_missing_or_outdated?)
            api_result = github_releases(release_project: @release_project_id)
            # api_result is a Sawyer-something, make it an array
            api_result.each do |release|
              @releases << release
            end
            cache_api_result_data(data: @releases,filename: releases_cache_file)
          else
            @releases = load_cached_api_result_data(filename: releases_cache_file)
          end
        end
        @releases
      end

      def releases_cache_file
        get_apicache_file(label: 'releases')
      end

      def release_cache_missing_or_outdated?
        return true if !File.exists?(releases_cache_file)
        cached_time = File.mtime(releases_cache_file)
        return (cached_time.to_date < Date.today)
      end

      def release_names
        releases.map{|r| !r.name.blank? ? r.name : nil}.compact
      end

      def latest_release(format: 'object')
        if(@latest_release.nil?)
          @latest_release = github_latest_release(release_project: @release_project_id)
        end
        case format
        when 'hash'
          @latest_release.to_h
        when 'filtered_hash'
          filtered_release_info(release: @latest_release)
        else
          @latest_release
        end
      end

      def release_version(release:)
        if(matches = release.name.match(K3D_VERSION_REGEX))
          version = Gem::Version.new(matches[:version])
        end
      end

      def filtered_release_info(release:)
        release_info = {}
        release_info['name'] = release.name
        release_info['version'] = release_version(release: release).to_s
        release_info['date'] = release.published_at.to_date
        release_info['download_url'] = download_url_for_github_release_and_asset(github_release: release, asset_name: @asset_name)
        release_info['checksum'] = checksum_for_release(release: release)
        release_info
      end

      def checksum_for_release(release:)
        download_asset = "sha256sum.txt"
        check_asset_string = "_dist/#{@asset_name}"
        # get the
        if(download_url = download_url_for_github_release_and_asset(github_release: release, asset_name: download_asset))
          tempfile = Down.download(download_url)
          filecontents = File.readlines(tempfile)
          filecontents.each do |line|
            line.chomp!
            (checksum,asset_string) = line.split("\s")
            if(asset_string == check_asset_string)
              return checksum
            end
          end
        end
        nil
      end

    end
  end
end