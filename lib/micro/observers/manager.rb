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

      def attach(observer, options = Utils::EMPTY_HASH)
        if options[:allow_duplication] || !included?(observer)
          @list << [:observer, observer, options[:data]]
        end

        self
      end

      def on(options = Utils::EMPTY_HASH)
        event, callable, with = options[:event], options[:call], options[:with]

        return self unless event.is_a?(Symbol) && callable.respond_to?(:call)

        arg = with.is_a?(Proc) ? with.call(@subject) : (arg || subject)

        @list << [:callable, event, [callable, arg]]
      end

      def detach(observer)
        @list.delete_if(&EqualTo[observer])

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
          return data[0].call(data[1]) if strategy == :callable && observer == with

          if strategy == :observer && observer.respond_to?(with)
            handler = observer.method(with)

            return handler.call(@subject) if handler.arity == 1

            handler.call(@subject, data)
          end
        end

      private_constant :EqualTo
    end

  end
end
