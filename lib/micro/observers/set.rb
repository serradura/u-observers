# frozen_string_literal: true

module Micro
  module Observers

    class Set
      def self.for(subject)
        new(subject)
      end

      def initialize(subject, subscribers: nil)
        @subject = subject
        @subject_changed = false
        @subscribers = Subscribers.new(subscribers)
      end

      def count; @subscribers.count; end
      def none?; @subscribers.none?; end
      def some?; !none?; end

      def subject_changed?
        @subject_changed
      end

      INVALID_BOOLEAN_MSG = 'expected a boolean (true, false)'.freeze

      def subject_changed(state)
        return @subject_changed = state if state == true || state == false

        raise ArgumentError, INVALID_BOOLEAN_MSG
      end

      def subject_changed!
        subject_changed(true)
      end

      def include?(observer)
        @subscribers.include?(observer)
      end
      alias included? include?

      def attach(*args); @subscribers.attach(args) and self; end
      def detach(*args); @subscribers.detach(args) and self; end

      def on(options = Utils::EMPTY_HASH); @subscribers.on(options) and self; end
      def once(options = Utils::EMPTY_HASH); @subscribers.once(options) and self; end

      def off(*args)
        @subscribers.off(args) and self
      end

      def notify(*events, data: nil)
        broadcast_if_subject_changed(Event::Names.fetch(events), data)
      end

      def notify!(*events, data: nil)
        broadcast(Event::Names.fetch(events), data)
      end

      CALL_EVENT = [:call].freeze

      def call(*events, data: nil)
        broadcast_if_subject_changed(Event::Names[events, default: CALL_EVENT], data)
      end

      def call!(*events, data: nil)
        broadcast(Event::Names[events, default: CALL_EVENT], data)
      end

      def inspect
        subs = @subscribers.to_inspect

        '#<%s @subject=%s @subject_changed=%p @subscribers=%p>' % [self.class, @subject, @subject_changed, subs]
      end

      private

        def broadcast_if_subject_changed(event_names, data = nil)
          return self if none? || !subject_changed?

          broadcast(event_names, data)

          subject_changed(false)

          self
        end

        def broadcast(event_names, data)
          return self if none?

          Broadcast.call(@subscribers, @subject, data, event_names)

          self
        end

      private_constant :INVALID_BOOLEAN_MSG, :CALL_EVENT
    end

  end
end
