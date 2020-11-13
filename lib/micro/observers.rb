require 'micro/observers/version'

module Micro
  module Observers
    require 'micro/observers/utils'
    require 'micro/observers/event'
    require 'micro/observers/subscribers'
    require 'micro/observers/broadcast'
    require 'micro/observers/set'

    def observers
      @__observers ||= Observers::Set.for(self)
    end
  end
end
