require 'sys-uname'
require 'etc'
module Rap
  class Utils
    def self.whoami
      Etc.getlogin || 'unknown'
    end

    def self.whereami
      Sys::Uname.nodename || 'unknown'
    end
  end
end
