require 'micro/observers/version'

module Micro
  module Observers
    require 'micro/observers/utils'
    require 'micro/observers/events_or_actions'
    require 'micro/observers/manager'

    module ClassMethods
      def notify_observers!(with:)
        proc { |object| with.each { |evt_or_act| object.observers.call(evt_or_act) } }
      end

      def notify_observers(*events)
        notify_observers!(with: EventsOrActions[events])
      end

      def call_observers(action: :call)
        notify_observers!(with: EventsOrActions[action])
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:private_class_method, :notify_observers!)
    end

    def observers
      @observers ||= Observers::Manager.for(self)
    end

  end
end
