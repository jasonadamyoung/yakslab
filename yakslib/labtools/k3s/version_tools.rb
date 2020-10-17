require 'octokit'
require 'down'

module LabTools
  module K3s
      class VersionTools
      K3S_VERSION_REGEX = %r{v(?<version>[\w|\.|-]+)\+k3s1}


      def k3s_version_regex
        K3S_VERSION_REGEX
      end

      def k3s_releases
        if(@k3s_release_list.nil?)
          client = Octokit::Client.new
          client.auto_paginate = true
          @k3s_release_list = client.list_releases('rancher/k3s')
        end
        @k3s_release_list
      end

      def k3s_release_names
        k3s_releases.map{|r| !r.name.blank? ? r.name : nil}.compact
      end

      def group_k3s_releases(ignore_preleases: true)
        if(@k3s_release_groups.nil?)
          @k3s_release_groups = {}
          k3s_releases.each do |release|
            next if(release.prerelease and ignore_preleases)
            if(matches = release.name.match(K3S_VERSION_REGEX))
              k3s_version = Gem::Version.new(matches[:version])
              release_hash = OpenStruct.new(name: release.name, version: k3s_version, release: release)
              (k3s_major,k3s_minor,k3s_patch) = k3s_version.segments
              @k3s_release_groups[k3s_major] = {} if(!@k3s_release_groups[k3s_major])

              if(@k3s_release_groups[k3s_major][k3s_minor])
                @k3s_release_groups[k3s_major][k3s_minor][release.name] = release_hash
                # latest check
                if(k3s_version > @k3s_release_groups[k3s_major][k3s_minor][:latest][:version])
                  @k3s_release_groups[k3s_major][k3s_minor][:latest] = release_hash
                end
              else
                @k3s_release_groups[k3s_major][k3s_minor] = {}
                @k3s_release_groups[k3s_major][k3s_minor][release.name] = release_hash
                @k3s_release_groups[k3s_major][k3s_minor][:latest] = release_hash
              end
            end
          end
        end
        @k3s_release_groups
      end


      def get_grouped_k3s_release_info(ignore_preleases: true)
        release_info = {}
        release_groupings = group_k3s_releases(ignore_preleases: ignore_preleases)
        release_groupings.keys.sort.each do |major_version|
          release_groupings[major_version].keys.sort.each do |minor_version|
            k8s_version = "#{major_version}.#{minor_version}"
            release_info[k8s_version] = {}
            lr = release_groupings[major_version][minor_version][:latest]
            release_info[k8s_version]["latest"] = {"name" => lr.name,
                                                  "version" => lr.version.to_s,
                                                  "date" => lr.release.published_at.to_date,
                                                  "checksum" => k3s_checksum_for_release(release: lr.release)}
            release_groupings[major_version][minor_version].select{|k,v| k != :latest}.each do |tag_name,release|
              key_name = "#{release.version.to_s}"
              release_info[k8s_version][key_name] = {"name" => release.name,
                                                     "version" => release.version.to_s,
                                                     "date" => release.release.published_at.to_date,
                                                     "checksum" => k3s_checksum_for_release(release: release.release)}
            end
          end
        end
        release_info
      end

      def get_k3s_latest_releases(ignore_preleases: true)
        release_information = {}
        k3s_latest_releases.each do |k8s_version,lr|
          release_information[k8s_version] = {name: lr.name, version: lr.version,
                                              date: lr.release.published_at.to_date,
                                              download_url: k3s_download_url_for_release(release: lr.release),
                                              checksum: k3s_checksum_for_release(release: lr.release)}
        end
        release_information
      end

      def k3s_latest_releases(ignore_preleases: true)
        @k3s_latest_releases = {}
        release_groupings = group_k3s_releases(ignore_preleases: ignore_preleases)
        release_groupings.keys.sort.each do |major_version|
          release_groupings[major_version].keys.sort.each do |minor_version|
            @k3s_latest_releases["#{major_version}.#{minor_version}"] = release_groupings[major_version][minor_version][:latest]
          end
        end
        @k3s_latest_releases
      end

      def get_k3s_latest_release(ignore_preleases: true)
        release_groupings = group_k3s_releases(ignore_preleases: ignore_preleases)
        max_major = release_groupings.keys.map{|major| major.to_i}.max
        max_minor = release_groupings[max_major].keys.map{|minor| minor.to_i}.max
        lr = release_groupings[max_major][max_minor][:latest]
        {name: lr.name,
         version: lr.version,
         date: lr.release.published_at.to_date,
         download_url: k3s_download_url_for_release(release: lr.release),
         checksum: k3s_checksum_for_release(release: lr.release)}
      end

      def k3s_checksum_for_release(release:, asset_name: 'k3s', checksum_arch: 'amd64')
        asset = "sha256sum-#{checksum_arch}.txt"
        if(download_url = k3s_download_url_for_release(release: release, asset_name: asset))
          tempfile = Down.download(download_url)
          filecontents = File.readlines(tempfile)
          filecontents.each do |line|
            line.chomp!
            (checksum,asset) = line.split("\s")
            if(asset == asset_name)
              return checksum
            end
          end
        end
        nil
      end


      def k3s_download_url_for_release(release:, asset_name: 'k3s')
        release[:assets].each do |asset|
          if(asset[:name] == asset_name)
            return asset[:browser_download_url]
          end
        end
        nil
      end

      def get_k3s_version(provided_version)
        if(provided_version == 'latest')
          (lr = get_k3s_latest_release) ? lr[:name] : nil
        elsif(provided_version.match(K3S_VERSION_REGEX))
          (k3s_release_names.include?(provided_version)) ? provided_version : nil
        else
          latest_releases = get_k3s_latest_releases
          (lr = latest_releases[provided_version]) ? lr[:name] : nil
        end
      end
    end
  end
end