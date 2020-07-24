require 'rap/deep_merge' unless defined?(DeepMerge)
require 'rap/options'
require 'rap/aplay'
require 'rap/utils'
require 'rap/vault'
require 'rap/dehydrated'

module Rap
  class RapError < StandardError; end

  def self.settings
    if(@settings.nil?)
      @settings = Rap::Options.new
      @settings.load!
      @settings
    end

    @settings
  end

end
