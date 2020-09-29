# frozen_string_literal: true

module Micro
  module Observers

    class Manager
      MapObserver = -> (observer, options) { [:observer, observer, options[:context]] }

      MapSubscribers = -> (value) do
        array = Utils.compact_array(value.kind_of?(Array) ? value : [])
        array.map { |observer| MapObserver[observer, Utils::EMPTY_HASH] }
      end

      EqualTo = -> (observer) do
        -> subscriber do
          handler = subscriber[0] == :observer ? subscriber[1] : subscriber[2][0]
          handler == observer
        end
      end

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

      INVALID_BOOLEAN_ERROR = 'expected a boolean (true, false)'.freeze

      def subject_changed(state)
        if state == true || state == false
          @subject_changed = state

          return self
        end

        raise ArgumentError, INVALID_BOOLEAN_ERROR
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
          @subscribers << MapObserver[observer, options] unless included?(observer)
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

        @subscribers << [:callable, event, [callable, with]]

        self
      end

      def notify!(events)
        return self unless subject_changed?

        broadcast(events)

        subject_changed(false)

        self
      end

      def notify(*events)
        notify!(Events[events])
      end

      def call(*events)
        broadcast(Events[events])

        self
      end

      private

        def broadcast(events)
          events.each do |event|
            @subscribers.each { |subscriber| call!(subscriber, event) }
          end
        end

        def call!(subscriber, event)
          strategy, observer, context = subscriber

          return call_observer(observer, event, context) if strategy == :observer

          return call_callable(context) if strategy == :callable && observer == event
        end

        def call_callable(context)
          callable, with = context[0], context[1]

          arg = with.is_a?(Proc) ? with.call(@subject) : (with || @subject)

          callable.call(arg)
        end

        def call_observer(observer, method_name, context)
          return unless observer.respond_to?(method_name)

          handler = observer.is_a?(Proc) ? observer : observer.method(method_name)

          handler.arity == 1 ? handler.call(@subject) : handler.call(@subject, context)
        end

      private_constant :MapObserver, :MapSubscribers, :EqualTo, :INVALID_BOOLEAN_ERROR
    end

  end
end
