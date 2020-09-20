require 'rap/deep_merge' unless defined?(DeepMerge)
require 'rap/options'
require 'rap/aplay'
require 'rap/utils'
require 'rap/vault'
require 'rap/dehydrated'
require 'rap/homelab'
require 'rap/k3s_tools.rb'


module Rap
  class RapError < StandardError; end

  def self.settings
    if(@settings.nil?)
      @settings = Rap::Options.new
      check_for_settings = File.expand_path("../../.rap-settings.yml", __FILE__)
      settings_file = File.exist?(check_for_settings) ? check_for_settings : nil
      @settings.files = settings_file
      @settings.load!
      @settings
    end

    @settings
  end

end
