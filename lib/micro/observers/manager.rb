# frozen_string_literal: true

module Micro
  module Observers

    class Manager
      EqualTo = -> (observer) do
        -> item { item[0] == :observer && item[1] == observer }
      end

      def self.for(subject)
        new(subject)
      end

      def initialize(subject, list = nil)
        @subject = subject

        @list = Utils.compact_array(list.kind_of?(Array) ? list : [])
      end

      def included?(observer)
        @list.any?(&EqualTo[observer])
      end

      def attach(*args)
        options = args.last.is_a?(Hash) ? args.pop : Utils::EMPTY_HASH

        Utils.compact_array(args).each do |observer|
          if options[:allow_duplication] || !included?(observer)
            @list << [:observer, observer, options[:data]]
          end
        end

        self
      end

      def on(options = Utils::EMPTY_HASH)
        event, callable, with = options[:event], options[:call], options[:with]

        return self unless event.is_a?(Symbol) && callable.respond_to?(:call)

        @list << [:callable, event, [callable, with]]
      end

      def detach(*args)
        Utils.compact_array(args).each do |observer|
          @list.delete_if(&EqualTo[observer])
        end

        self
      end

      def notify(*events)
        broadcast(EventsOrActions[events])

        self
      end

      def call(options = Utils::EMPTY_HASH)
        broadcast(EventsOrActions.fetch_actions(options))

        self
      end

      private

        def broadcast(evts_or_acts)
          evts_or_acts.each do |evt_or_act|
            @list.each do |strategy, observer, data|
              call!(observer, strategy, data, with: evt_or_act)
            end
          end
        end

        def call!(observer, strategy, data, with:)
          return call_callable(data) if strategy == :callable && observer == with

          return call_observer(observer, with, data) if strategy == :observer
        end

        def call_callable(data)
          callable, arg = data[0], data[1]

          callable_arg = arg.is_a?(Proc) ? arg.call(@subject) : (arg || @subject)

          callable.call(callable_arg)
        end

        def call_observer(observer, method_name, data)
          return unless observer.respond_to?(method_name)

          handler = observer.method(method_name)

          handler.arity == 1 ? handler.call(@subject) : handler.call(@subject, data)
        end

      private_constant :EqualTo
    end

  end
end
