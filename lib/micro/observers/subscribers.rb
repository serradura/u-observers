# frozen_string_literal: true

module Micro
  module Observers

    class Subscribers
      EqualTo = -> (observer) { -> subscriber { GetObserver[subscriber] == observer } }
      GetObserver = -> subscriber { subscriber[0] == :observer ? subscriber[1] : subscriber[2][0] }
      MapObserver = -> (observer, options, once) { [:observer, observer, options[:context], once] }
      MapObserversToInitialize = -> arg do
        Utils::Arrays.flatten_and_compact(arg).map do |observer|
          MapObserver[observer, Utils::EMPTY_HASH, false]
        end
      end

      attr_reader :list

      def initialize(arg)
        @list = arg.is_a?(Array) ? MapObserversToInitialize[arg] : []
      end

      def to_inspect
        none? ? @list : @list.map(&GetObserver)
      end

      def count
        @list.size
      end

      def none?
        @list.empty?
      end

      def include?(subscriber)
        @list.any?(&EqualTo[subscriber])
      end

      def attach(args)
        options = args.last.is_a?(Hash) ? args.pop : Utils::EMPTY_HASH

        once = options.frozen? ? false : options.delete(:perform_once)

        Utils::Arrays.fetch_from_args(args).each do |observer|
          @list << MapObserver[observer, options, once] unless include?(observer)
        end

        true
      end

      def detach(args)
        Utils::Arrays.fetch_from_args(args).each do |observer|
          delete_observer(observer)
        end

        true
      end

      def on(options)
        on!(options, once: false)
      end

      def once(options)
        on!(options, once: true)
      end

      EventNameToCall = -> event_name { -> subscriber { subscriber[0] == :callable && subscriber[1] == event_name } }

      def off(args)
        Utils::Arrays.fetch_from_args(args).each do |value|
          if value.is_a?(Symbol)
            @list.delete_if(&EventNameToCall[value])
          else
            delete_observer(value)
          end
        end
      end

      private

        def delete_observer(observer)
          @list.delete_if(&EqualTo[observer])
        end

        def on!(options, once:)
          event, callable, with, context = options[:event], options[:call], options[:with], options[:context]

          return true unless event.is_a?(Symbol) && callable.respond_to?(:call)

          observer = [callable, with, context]

          @list << [:callable, event, observer, once] unless include_callable?(event, observer)

          true
        end

        CallableHaving = -> (event, observer) do
          -> subs { subs[0] == :callable && subs[1] == event && subs[2] == observer }
        end

        def include_callable?(event, observer)
          @list.any?(&CallableHaving[event, observer])
        end

      private_constant :EqualTo, :EventNameToCall, :CallableHaving
      private_constant :GetObserver, :MapObserver, :MapObserversToInitialize
    end

    private_constant :Subscribers
  end
end
