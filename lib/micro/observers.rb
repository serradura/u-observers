require 'micro/observers/version'

module Micro
  module Observers
    require 'micro/observers/manager'

    module ClassMethods
      def call_observers(with: :call)
        proc do |object|
          Array(with)
            .each { |action| object.observers.call(object, action: action) }
        end
      end

      def notify_observers(with: :call)
        call_observers(with: with)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def observers
      @observers ||= Observers::Manager.new
    end

  end
end
