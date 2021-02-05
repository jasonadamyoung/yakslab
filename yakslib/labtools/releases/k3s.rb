require 'octokit'
require 'down'
require_relative 'tools'

module LabTools
  module Releases
    class K3s
      include LabTools::Releases::Tools
      K3S_VERSION_REGEX = %r{v(?<version>[\w|\.|-]+)\+k3s(?<k3spatch>\d)}
      RELEASE_PROJECT = 'k3s-io/k3s'

      def initialize(options: {})
        @release_data_source = 'github'
        @api_cache_dir = options[:api_cache_dir] || './apicache'
        @ignore_prelease = options[:ignore_prelease] || true
        @release_project_id = RELEASE_PROJECT
        @architecture = options[:architecture] || 'amd64'
        @platform = options[:platform] || 'linux'
        @asset_name = "k3s"
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

      def grouped_release_objects
        if(@grouped_release_objects.nil?)
          @grouped_release_objects = {}
          releases.each do |release|
            next if(release.prerelease and @ignore_prelease)
            if(matches = release.name.match(K3S_VERSION_REGEX))
              k3s_version = release_k3s_version(release: release)
              kube_version = release_kube_version(release: release)
              (kube_major,kube_minor,kube_patch) = kube_version.segments
              @grouped_release_objects[kube_major] = {} if(!@grouped_release_objects[kube_major])

              if(@grouped_release_objects[kube_major][kube_minor])
                @grouped_release_objects[kube_major][kube_minor][release.name] = release
                # latest check
                if(k3s_version > release_k3s_version(release: @grouped_release_objects[kube_major][kube_minor]["latest"]))
                  @grouped_release_objects[kube_major][kube_minor]["latest"] = release
                end
              else
                @grouped_release_objects[kube_major][kube_minor] = {}
                @grouped_release_objects[kube_major][kube_minor][release.name] = release
                @grouped_release_objects[kube_major][kube_minor]["latest"] = release
              end
            end
          end
        end
        @grouped_release_objects
      end

      def filtered_release_info(release:)
        release_info = {}
        release_info['name'] = release.name
        release_info['version'] = release_kube_version(release: release).to_s
        release_info['k3s_version'] = release_k3s_version(release: release).to_s
        release_info['date'] = release.published_at.to_date
        release_info['download_url'] = download_url_for_github_release_and_asset(github_release: release, asset_name: @asset_name)
        release_info['checksum'] = checksum_for_release(release: release)
        release_info
      end

      def format_release(format:, release:)
        if(format == 'hash')
          release.to_h
        elsif(format == 'filtered_hash')
          filtered_release_info(release: release)
        else
          release
        end
      end

      def grouped_releases(format: 'filtered_hash')
        grouped_releases = {}
        grouped_release_objects.each do |kube_major,major_releases|
          major_releases.each do |kube_minor,minor_releases|
            key_name = "#{kube_major}.#{kube_minor}"
            grouped_releases[key_name] = {}
            minor_releases.each do |name,release|
              grouped_releases[key_name][name] = format_release(format: format, release: release)
            end
          end
        end
        grouped_releases
      end


      def latest_releases(format: 'filtered_hash')
        latest_releases = {}
        grouped_release_objects.keys.sort.each do |major_version|
          grouped_release_objects[major_version].keys.sort.each do |minor_version|
            release = grouped_release_objects[major_version][minor_version]["latest"]
            latest_releases["#{major_version}.#{minor_version}"] = format_release(format: format, release: release)
          end
        end
        latest_releases
      end

      def latest_release(format: 'filtered_hash')
        max_major = grouped_release_objects.keys.map{|major| major.to_i}.max
        max_minor = grouped_release_objects[max_major].keys.map{|minor| minor.to_i}.max
        lr = grouped_release_objects[max_major][max_minor]["latest"]
        format_release(format: format, release: lr)
      end

      def checksum_for_release(release:)
        if(@checksums.nil?)
          @checksums = {}
        end

        key_name = "#{release.name}-#{@architecture}"

        if(@checksums[key_name].nil?)
          download_asset = "sha256sum-#{@architecture}.txt"
          if(download_url = download_url_for_github_release_and_asset(github_release: release, asset_name: download_asset))
            # sloooooow in a loop
            tempfile = Down.download(download_url)
            filecontents = File.readlines(tempfile)
            filecontents.each do |line|
              line.chomp!
              (checksum,asset) = line.split("\s")
              if(asset == @asset_name)
                @checksums[key_name] = checksum
                return @checksums[key_name]
              end
            end
          end
        end
        @checksums[key_name]
      end

      def release_k3s_version(release:)
        if(matches = release.name.match(K3S_VERSION_REGEX))
          k3s_patch = matches[:k3spatch]
          kube_version = Gem::Version.new(matches[:version])
          k3s_version = Gem::Version.new("#{matches[:version]}.#{k3s_patch}")
        end
        k3s_version
      end

      def release_kube_version(release:)
        if(matches = release.name.match(K3S_VERSION_REGEX))
          k3s_patch = matches[:k3spatch]
          kube_version = Gem::Version.new(matches[:version])
        end
        kube_version
      end

      def k3s_name_for_version(provided_version)
        if(provided_version == 'latest')
          (lr = latest_release) ? lr["name"] : nil
        elsif(provided_version.match(K3S_VERSION_REGEX))
          (release_names.include?(provided_version)) ? provided_version : nil
        else
          (lr = latest_releases[provided_version]) ? lr["name"] : nil
        end
      end
    end
  end
end