require_relative '../labcommand'

module LabCommand
  module Releases
    class GitLab < LabCommand::Base
      DEFAULT_VERSION = 'backports'
      DEFAULT_EDITION = 'EE'
      def initialize(version: 'default', options:)
        @edition = options[:edition] ? options[:edition].strip.upcase : DEFAULT_EDITION
        @show_version = (version == 'default') ? DEFAULT_VERSION : version
        @output_format = options[:output] || 'default'
        @release_tools = LabTools::Releases::GitLab.new
        @options = options
      end


      def 🚀

        data_format = (@output_format =~ /^raw/) ? 'hash' : 'filtered_hash'

        case @show_version
        when 'backports'
          release_and_tag_data = @release_tools.backports_release_tags(format: data_format)
        when 'latest'
          release_and_tag_data = @release_tools.latest_release_tag(format: data_format)
        when 'grouped'
          release_and_tag_data = @release_tools.grouped_tags_and_releases(format: data_format)
        else #assume version number
          release_and_tag_data = @release_tools.latest_release_tag_for_version(version_number: @show_version, format: data_format)
        end

        case @output_format
        when 'json'
          puts JSON.pretty_generate(release_and_tag_data)
        when 'yaml'
          puts release_and_tag_data.to_yaml
        when 'raw_json'
          puts JSON.pretty_generate(release_and_tag_data)
        when 'raw_yaml'
          puts release_and_tag_data.to_yaml
        else # default (formatted)
          formatted_output(release_and_tag_data)
        end

      end

      def formatted_output(release_and_tag_data)
        case @show_version
        when 'backports'
          puts "Latest Backport Releases and Tags for GitLab #{@edition}"
          release_and_tag_data.each do |release_and_tag|
            puts "---"
            formatted_release(release_and_tag["release"])
            puts "\n"
            formatted_tag(release_and_tag["tag"])
          end
        when 'latest'
          puts "Latest Release and Tag for GitLab #{@edition}"
          puts "---"
          formatted_release(release_and_tag_data["release"])
          puts "\n"
          formatted_tag(release_and_tag_data["tag"])
        when 'grouped'
          puts "Formatted group output is not available. Please use --output={json,yaml,raw_json,raw_yaml}"
        else # assume version number
          if(release_and_tag_data.nil?)
            puts "No Release Information for GitLab #{@edition} #{@show_version}"
            exit(1)
          end
          puts "Latest Release and Tag for GitLab #{@edition} #{@show_version}"
          puts "---"
          formatted_release(release_and_tag_data["release"])
          puts "\n"
          formatted_tag(release_and_tag_data["tag"])
        end
      end


      def formatted_release(release_info)
        puts "Release Version: #{release_info['version']}"
        puts "Release Date:    #{release_info['date'].to_s}"
        puts "Release URL:     #{release_info['url']}"
        puts "Release Post:    #{release_info['post']}"
      end

      def formatted_tag(tag_info)
        puts "Tag Name:        #{tag_info['name']}"
        puts "Tag Version:     #{tag_info['version']}"
        puts "Tag Date:        #{tag_info['date'].to_s}"
        puts "Tag URL:         #{tag_info['url']}"
      end


    end
  end
end
