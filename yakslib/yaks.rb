require 'yaks/deep_merge' unless defined?(DeepMerge)
require 'yaks/options'
require 'yaks/dehydrated'
require 'yaks/homelab'
require 'yaks/k3s_tools'
require 'yaks/ansible_playbook'
require 'yaks/ansible_vault'


module Yaks
  class YaksError < StandardError; end

  def self.settings
    if(@settings.nil?)
      @settings = Yaks::Options.new
      @settings.load!
      yaksdir = File.expand_path("../../", __FILE__)
      @settings.yaksdir = yaksdir
      @settings
    end

    @settings
  end

end
