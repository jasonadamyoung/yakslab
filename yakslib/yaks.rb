require 'labtools/core'
require 'yaks/dehydrated'
require 'yaks/homelab'

module Yaks
  class YaksError < StandardError; end

  def self.settings
    if(@settings.nil?)
      yaksdir = File.expand_path("../../", __FILE__)
      @settings = LabTools::Options.new
      @settings.files = File.join(yaksdir,".yaks.yml")
      @settings.load!
      @settings.yaksdir = yaksdir
      @settings
    end

    @settings
  end

end
