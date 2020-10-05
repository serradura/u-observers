# frozen_string_literal: true

module Micro
  module Observers

    class Manager
      MapSubscriber = -> (observer, options) { [:observer, observer, options[:context]] }

      MapSubscribers = -> (value) do
        array = Utils.compact_array(value.kind_of?(Array) ? value : [])
        array.map { |observer| MapSubscriber[observer, Utils::EMPTY_HASH] }
      end

      GetObserver = -> subscriber { subscriber[0] == :observer ? subscriber[1] : subscriber[2][0] }

      EqualTo = -> (observer) { -> subscriber { GetObserver[subscriber] == observer } }

      def self.for(subject)
        new(subject)
      end

      def initialize(subject, subscribers: nil)
        @subject = subject

        @subject_changed = false

        @subscribers = MapSubscribers.call(subscribers)
      end

      def count
        @subscribers.size
      end

      def none?
        @subscribers.empty?
      end

      def some?
        !none?
      end

      def subject_changed?
        @subject_changed
      end

      INVALID_BOOLEAN_MSG = 'expected a boolean (true, false)'.freeze

      def subject_changed(state)
        if state == true || state == false
          @subject_changed = state

          return self
        end

        raise ArgumentError, INVALID_BOOLEAN_MSG
      end

      def subject_changed!
        subject_changed(true)
      end

      def included?(observer)
        @subscribers.any?(&EqualTo[observer])
      end

      def attach(*args)
        options = args.last.is_a?(Hash) ? args.pop : Utils::EMPTY_HASH

        Utils.compact_array(args).each do |observer|
          @subscribers << MapSubscriber[observer, options] unless included?(observer)
        end

        self
      end

      def detach(*args)
        Utils.compact_array(args).each do |observer|
          @subscribers.delete_if(&EqualTo[observer])
        end

        self
      end

      def on(options = Utils::EMPTY_HASH)
        event, callable, with = options[:event], options[:call], options[:with]

        return self unless event.is_a?(Symbol) && callable.respond_to?(:call)

        @subscribers << [:callable, event, [callable, with]] unless included?(callable)

        self
      end

      def notify(*events)
        broadcast_if_subject_changed(Events.fetch(events))

        self
      end

      def notify!(*events)
        broadcast(Events.fetch(events))

        self
      end

      CALL_EVENT = [:call].freeze

      def call(*events)
        broadcast_if_subject_changed(Events[events, default: CALL_EVENT])

        self
      end

      def call!(*events)
        broadcast(Events[events, default: CALL_EVENT])

        self
      end

      def inspect
        subs = @subscribers.empty? ? @subscribers : @subscribers.map(&GetObserver)

        '<#%s @subject=%s @subject_changed=%p @subscribers=%p>' % [self.class, @subject, @subject_changed, subs]
      end

      private

        def broadcast_if_subject_changed(events)
          return unless subject_changed?

          broadcast(events)

          subject_changed(false)
        end

        def broadcast(events)
          return if @subscribers.empty?

          events.each do |event|
            @subscribers.each do |strategy, observer, context|
              case strategy
              when :observer then notify_observer(observer, event, context)
              when :callable then notify_callable(observer, event, context)
              end
            end
          end
        end

        def notify_observer(observer, method_name, context)
          return unless observer.respond_to?(method_name)

          handler = observer.is_a?(Proc) ? observer : observer.method(method_name)

          handler.arity == 1 ? handler.call(@subject) : handler.call(@subject, context)
        end

        def notify_callable(expected_event, event, context)
          return if expected_event != event

          callable, with = context[0], context[1]

          arg = with.is_a?(Proc) ? with.call(@subject) : (with || @subject)

          callable.call(arg)
        end

      private_constant :INVALID_BOOLEAN_MSG, :CALL_EVENT
      private_constant :MapSubscriber, :MapSubscribers, :GetObserver, :EqualTo
    end

  end
end
