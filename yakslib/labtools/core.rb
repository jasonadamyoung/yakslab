require_relative 'deep_merge' unless defined?(DeepMerge)
require_relative 'options'

require_relative 'ansible/playbook'
require_relative 'ansible/vault'
require_relative 'k3s/version_tools'
require_relative 'k3d/remote_tools'

class LabToolsError < StandardError; end

module LabTools
  class Core
  end
end