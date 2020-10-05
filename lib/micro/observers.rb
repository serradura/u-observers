require 'micro/observers/version'

module Micro
  module Observers
    require 'micro/observers/utils'
    require 'micro/observers/events'
    require 'micro/observers/manager'

    module ClassMethods
      def notify_observers!(events)
        proc do |object|
          object.observers.subject_changed!
          object.observers.send(:broadcast_if_subject_changed, events)
        end
      end

      def notify_observers(*events)
        notify_observers!(Events.fetch(events))
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
