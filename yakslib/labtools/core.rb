require_relative 'deep_merge' unless defined?(DeepMerge)
require_relative 'options'

require_relative 'ansible/playbook'
require_relative 'ansible/vault'
require_relative 'k3s/remote_tools'
require_relative 'k3d/remote_tools'
require_relative 'kubernetes/cluster'
require_relative 'kubernetes/configuration'
require_relative 'kubernetes/service_account'

require_relative 'releases/gitlab'
require_relative 'releases/k3d'
require_relative 'releases/k3s'

class LabToolsError < StandardError; end

module LabTools
  class Core
  end
end