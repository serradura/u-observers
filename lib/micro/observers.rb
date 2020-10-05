require 'micro/observers/version'

module Micro
  module Observers
    require 'micro/observers/utils'
    require 'micro/observers/event'
    require 'micro/observers/manager'

    def observers
      @__observers ||= Observers::Manager.for(self)
    end
  end
end
