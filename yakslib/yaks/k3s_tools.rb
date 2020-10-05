require 'octokit'

module Yaks
  class K3sTools
    K3S_VERSION_REGEX = %r{v(?<version>[\w|\.|-]+)\+k3s1}

    def k3s_releases
      if(@k3s_release_list.nil?)
        client = Octokit::Client.new
        client.auto_paginate = true
        @k3s_release_list = client.list_releases('rancher/k3s')
      end
      @k3s_release_list
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

    def get_k3s_latest_releases(ignore_preleases: true)
      release_information = {}
      k3s_latest_releases.each do |k8s_version,lr|
        release_information[k8s_version] = {name: lr.name, version: lr.version, date: lr.release.published_at.to_date, download_url: k3s_download_url_for_release(release: lr.release) }
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

    def k3s_download_url_for_release(release:, asset_name: 'k3s')
      release[:assets].each do |asset|
        if(asset[:name] == asset_name)
          return asset[:browser_download_url]
        end
      end
      nil
    end


  end
end