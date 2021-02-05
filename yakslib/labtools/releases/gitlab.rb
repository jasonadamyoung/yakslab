require 'labclient'
require_relative 'tools'

# This class will use the labclient api to get information about GitLab (either EE or gitlab-foss)
# releases and tags - because the api calls can take a well - the class will marshall the return
# values to a cache file

# releases are kept for up to a month - re-checking on/after the 22nd
# tags are kept indefinitely for older releases, and pulled hourly for the last three (backport)
# releases - because a security backport could be released at any time - individual tag
# requests are performative

module LabTools
  module Releases
    class GitLab
      include LabTools::Releases::Tools
      GITLAB_VERSION_REGEX = %r{v(?<version>[\w|\.|-]+)}

      GITLAB_RELEASE_DAY = 22
      BACKPORT_TAG_CACHE_TIME = 1.hour

      # project id's for gitlab and gitlab-foss @ gitlab.com
      GITLAB_INSTANCE_URL = 'https://gitlab.com'
      GITLAB_FOSS_PROJECT_ID = 13083
      GITLAB_PROJECT_ID = 278964

      def initialize(options: {})
        @release_data_source = 'gitlab'
        @api_cache_dir = options[:api_cache_dir] || './apicache'
        @gitlab_edition = options[:edition] ? options[:edition].upcase : 'EE'
        @gitlab_instance_url = options[:gitlab_instance_url] || GITLAB_INSTANCE_URL
        if(@gitlab_instance_url == GITLAB_INSTANCE_URL)
          @gitlab_token = ''
          case @gitlab_edition
          when 'EE'
            @gitlab_project_id = GITLAB_PROJECT_ID
          when 'CE'
            @gitlab_project_id = GITLAB_FOSS_PROJECT_ID
          end
        else
          @gitlab_token = options[:gitlab_token]
          @gitlab_project_id = options[:gitlab_project_id]
        end
        @release_project = gitlab_project(release_project: @gitlab_project_id)
        @ignore_prelease = options[:ignore_prelease] || true
      end

      def is_edition_ee?
        @gitlab_edition == 'EE'
      end

      def refresh_releases_and_tags
        releases(force_cache_update: true).each do |r|
          tags_for_release(release: r,force_cache_update: true)
        end
      end


      def gitlab_releases_cache_file
        (is_edition_ee?) ? get_apicache_file(label: 'releases') : get_apicache_file(label: 'foss_releases')
      end

      def releases(force_cache_update: false)
        if(@releases.nil?)
          @releases = []
          # check cache
          if(force_cache_update or release_cache_missing_or_outdated?)
            api_result = gitlab_releases(release_project: @gitlab_project_id)
            if(!api_result.success?)
              raise LabToolsError, "GitLab release request returned #{api_result.code}"
            end
            # api_result is a LabClient::PaginatedResource - make it an array
            api_result.each do |release|
              if(is_edition_ee?)
                next unless (is_ee_tag?(tag_name: release.tag_name))
              end
              @releases << release
            end
            cache_api_result_data(data: @releases,filename: gitlab_releases_cache_file)
          else
            @releases = load_cached_api_result_data(filename: gitlab_releases_cache_file)
          end
        end
        @releases
      end

      def releases_are_cached?
        !release_cache_missing_or_outdated?
      end

      def tags_are_cached_for_release?(release: r)
        !tags_cache_missing_or_outdated_for_release?(release: release)
      end

      def backport_releases
        releases.slice(0,3)
      end

      def latest_release
        releases.first
      end



      def tags_for_release(release:, force_cache_update: false)
        if(@release_tags.nil?)
          @release_tags = {}
        end

        if(!@release_tags[release.tag_name])
          if(force_cache_update or tags_cache_missing_or_outdated_for_release?(release: release))
            api_result = gitlab_tags(release_project: @gitlab_project_id, options: {search: tag_search_string(release: release)})
            raise LabToolsError, "GitLab tags request returned #{api_result.code}" if(!api_result.success?)
            @release_tags[release.tag_name] = []
            api_result.each do |tag|
              if(is_edition_ee?)
                next unless (is_ee_tag?(tag_name: tag.name))
              end
              @release_tags[release.tag_name] << tag
            end
            cache_api_result_data(data: @release_tags[release.tag_name],filename: tag_cache_file_for_release(release: release))
          else
            @release_tags[release.tag_name] = load_cached_api_result_data(filename: tag_cache_file_for_release(release: release))
          end
        end
        # filter out the returned tags
        if(!@ignore_prelease)
          @release_tags[release.tag_name]
        else
          @release_tags[release.tag_name].select{|t| (!(tag_version(tag: t).prerelease?))}
        end
      end

      def latest_tag_for_release(release:)
        if(@latest_release_tags.nil?)
          @latest_release_tags = {}
        end
        tags_for_release(release: release).each do |tag|
          version = tag_version(tag: tag)
          (major,minor,patch) = version.segments
          if(@latest_release_tags[release.tag_name])
            latest_version = tag_version(tag: @latest_release_tags[release.tag_name])
            if(version > latest_version)
              @latest_release_tags[release.tag_name] = tag
            end
          else
            @latest_release_tags[release.tag_name] = tag
          end
        end
        @latest_release_tags[release.tag_name]
      end


      def tags_for_version(version_number: 'all')
        tags = []
        if(version_number.nil? or version_number == 'all')
          releases.each do |release|
            tags += tags_for_release(release: release)
          end
        else
          version = Gem::Version.new(version_number)
          (major,minor,rest) = version.segments
          return nil if grouped_release_objects[major].nil?
          if(!minor.nil?)
            release = grouped_release_objects[major]["#{major}.#{minor}"]
            tags += tags_for_release(release: release)
          else
            grouped_release_objects[major].keys.each do |label|
              next if(["previous","latest"].include?(label))
              release = grouped_release_objects[major][label]
              tags += tags_for_release(release: release)
            end
          end
        end
        tags
      end

      def grouped_release_objects
        if(@grouped_release_objects.nil?)
          @grouped_release_objects = {}
          @grouped_release_objects["latest"] = releases.first
          releases.each do |r|
            version = release_version(release: r)
            (major,minor,patch) = version.segments
            major_version = major.to_s
            if(@grouped_release_objects[major_version])
              @grouped_release_objects[major_version]["#{major}.#{minor}"] = r
              latest_version = release_version(release: @grouped_release_objects[major_version]["latest"])
              if(version > latest_version)
                @grouped_release_objects[major_version]["previous"] = latest_version
                @grouped_release_objects[major_version]["latest"] = r
              end
            else
              @grouped_release_objects[major_version] = {"#{major}.#{minor}" => r, "latest" => r}
            end
          end
        end
        @grouped_release_objects
      end

      def grouped_tags(format: 'object')
        grouped_tags = {}
        grouped_tags["latest"] = format_tag_or_release(format: format, tag_or_release: latest_tag_for_release(release: latest_release))
        grouped_release_objects.each do |major_version,minor_releases|
          next if(["previous","latest"].include?(major_version))
          grouped_tags[major_version] = {}
          grouped_tags[major_version]["latest"] = format_tag_or_release(format: format, tag_or_release: latest_tag_for_release(release: grouped_release_objects[major_version]["latest"]))
          minor_releases.select{|k,v| k != "latest"}.each do |major_minor, release|
            grouped_tags[major_version][major_minor] = {}
            grouped_tags[major_version][major_minor]["latest"] = format_tag_or_release(format: format, tag_or_release: latest_tag_for_release(release: release))
            tags = tags_for_release(release: release)
            tags.each do |tag|
              key_name = tag_version(tag: tag).to_s
              grouped_tags[major_version][major_minor][key_name] = format_tag_or_release(format: format, tag_or_release: tag)
            end
          end
        end
        grouped_tags
      end

      def grouped_tags_and_releases(format: 'object')
        grouped_tags_and_releases = {}
        grouped_tags_hash = grouped_tags(format: format)
        grouped_tags_hash.each do |major_version,minor_groups|
          if(major_version == "latest")
            release = grouped_release_objects["latest"]
            tag = grouped_tags_hash["latest"]
            grouped_tags_and_releases["latest_release"] = format_tag_or_release(format: format, tag_or_release: release)
            grouped_tags_and_releases["latest"] = tag
          else
            grouped_tags_and_releases[major_version] = {}
            release = grouped_release_objects[major_version]["latest"]
            tag = grouped_tags_hash[major_version]["latest"]
            grouped_tags_and_releases[major_version]["latest_release"] = format_tag_or_release(format: format, tag_or_release: release)
            grouped_tags_and_releases[major_version]["latest"] = tag
            minor_groups.each do |major_minor_version,data|
              next if major_minor_version == "latest"
              grouped_tags_and_releases[major_version][major_minor_version] = {}
              release = grouped_release_objects[major_version][major_minor_version]
              grouped_tags_and_releases[major_version][major_minor_version]["release"] = format_tag_or_release(format: format, tag_or_release: release)
              data.each do |key,values|
                grouped_tags_and_releases[major_version][major_minor_version][key] = values
              end
            end
          end
        end
        grouped_tags_and_releases
      end

      def format_tag_or_release(format:, tag_or_release:)
        if(format == 'hash')
          tag_or_release.to_h
        elsif(format == 'filtered_hash')
          if(tag_or_release.is_a?(LabClient::ProjectRelease))
            filtered_release_info(release: tag_or_release)
          elsif(tag_or_release.is_a?(LabClient::Tag))
            filtered_tag_info(tag: tag_or_release)
          else
            tag_or_release.to_h
          end
        else
          tag_or_release
        end
      end

      def filtered_release_info(release:)
        release_info = {}
        release_info['version'] = release_version(release: release).to_s
        release_info['date'] = release.released_at.to_date
        release_info['url'] = release&._links&.self
        release_info['post'] = release&.assets&.links[0]&.url
        release_info
      end

      def filtered_tag_info(tag:)
        tag_info = {}
        tag_info['name'] = tag.name
        tag_info['version'] = tag_version(tag: tag).to_s
        tag_info['url'] = tag_url(tag_name: tag.name)
        tag_info['date'] = tag.commit.created_at.to_date
        tag_info
      end

      def latest_release_tag(format: 'object')
        release = latest_release
        tag = latest_tag_for_release(release: release)
        case format
        when 'hash'
          {"release" => release.to_h, "tag" => tag.to_h}
        when 'filtered_hash'
          {"release" => filtered_release_info(release: release), "tag" =>  filtered_tag_info(tag: tag)}
        else
          {"release" => release, "tag" =>  tag}
        end
      end

      def backports_release_tags(format: 'object')
        releases_tags = []
        backport_releases.each do |release|
          tag = latest_tag_for_release(release: release)
          case format
          when 'hash'
            releases_tags << {"release" => release.to_h, "tag" => tag.to_h}
          when 'filtered_hash'
            releases_tags << {"release" => filtered_release_info(release: release), "tag" =>  filtered_tag_info(tag: tag)}
          else
            releases_tags << {"release" => release, "tag" => tag}
          end
        end
        releases_tags
      end

      def latest_release_tag_for_version(version_number:,format: 'object')
        version = Gem::Version.new(version_number)
        (major,minor,rest) = version.segments
        major_version = major.to_s
        return nil if grouped_release_objects[major_version].nil?
        if(!minor.nil?)
          release = grouped_release_objects[major_version]["#{major}.#{minor}"]
          latest_tag = latest_tag_for_release(release: release)
        else
          release = grouped_release_objects[major_version]["latest"]
          latest_tag = latest_tag_for_release(release: release)
        end

        case format
        when 'hash'
          {"release" =>release.to_h, "tag" => latest_tag.to_h}
        when 'filtered_hash'
          {"release" => filtered_release_info(release: release), "tag" => filtered_tag_info(tag: latest_tag)}
        else
          {"release" => release, "tag" => latest_tag}
        end
      end

      def tag_url(tag_name:)
        "#{@release_project.web_url}/-/tags/#{tag_name}"
      end

      def is_ee_tag?(tag_name:)
        tag_name =~ %r{-ee$}
      end

      def is_backport_release?(release:)
        backport_releases.include?(release)
      end

      def backport_release_versions
        backport_releases.map{|r| release_version(release: r)}
      end

      def tag_cache_file_for_release(release:)
        label = is_edition_ee? ? "#{release.tag_name}_tags" : "#{release.tag_name}_tags_foss"
        get_apicache_file(label: label)
      end

      def tags_cache_missing_or_outdated_for_release?(release:)
        cache_file = tag_cache_file_for_release(release: release)
        return true if !File.exists?(cache_file)
        return false if !is_backport_release?(release: release)
        cached_time = File.mtime(cache_file)
        return ((Time.now - BACKPORT_TAG_CACHE_TIME) >= cached_time)
      end

      def release_cache_missing_or_outdated?
        return true if !File.exists?(gitlab_releases_cache_file)
        cached_time = File.mtime(gitlab_releases_cache_file)
        # on day of - will keep treating it as outdated
        if(cached_time.to_date == last_release_date)
          return ((Time.now - BACKPORT_TAG_CACHE_TIME) >= cached_time)
        else
          return (cached_time.to_date < last_release_date)
        end
      end


      def last_release_date
        @last_month = (@today = Date.today)-1.month
        if(@today.day >= GITLAB_RELEASE_DAY)
          Date.new(@today.year,@today.month,GITLAB_RELEASE_DAY)
        else
          Date.new(@last_month.year,@last_month.month,GITLAB_RELEASE_DAY)
        end
      end

      def release_version(release:)
        tag_without_ee = release.tag_name.gsub(/-ee/,'')
        if(matches = tag_without_ee.match(GITLAB_VERSION_REGEX))
          gitlab_version = Gem::Version.new(matches[:version])
        end
        gitlab_version
      end

      def tag_version(tag:)
        if(tag.is_a?(LabClient::Tag))
          tag_name = tag.name
        else
          tag_name = tag
        end
        tag_without_ee = tag_name.gsub(/-ee/,'')
        if(matches = tag_without_ee.match(GITLAB_VERSION_REGEX))
          tag_version = Gem::Version.new(matches[:version])
        end
        tag_version
      end

      def tag_search_string(release:)
        gitlab_version = release_version(release: release)
        (major,minor,patch) = gitlab_version.segments
        "^v#{major}.#{minor}."
      end

    end
  end
end