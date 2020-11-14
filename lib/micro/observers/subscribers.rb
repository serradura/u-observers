# frozen_string_literal: true

module Micro
  module Observers

    class Subscribers
      EqualTo = -> (observer) { -> subscriber { GetObserver[subscriber] == observer } }
      GetObserver = -> subscriber { subscriber[0] == :observer ? subscriber[1] : subscriber[2][0] }
      MapObserver = -> (observer, options, once) { [:observer, observer, options[:context], once] }
      MapObserverWithoutContext = -> observer { MapObserver[observer, Utils::EMPTY_HASH, false] }

      attr_reader :relation

      def initialize(arg)
        array = Utils::Arrays.flatten_and_compact(arg.kind_of?(Array) ? arg : [])
        @relation = array.map(&MapObserverWithoutContext)
      end

      def to_inspect
        none? ? @relation : @relation.map(&GetObserver)
      end

      def count
        @relation.size
      end

      def none?
        @relation.empty?
      end

      def include?(subscriber)
        @relation.any?(&EqualTo[subscriber])
      end

      def attach(args)
        options = args.last.is_a?(Hash) ? args.pop : Utils::EMPTY_HASH

        once = options.frozen? ? false : options.delete(:perform_once)

        Utils::Arrays.flatten_and_compact(args).each do |observer|
          @relation << MapObserver[observer, options, once] unless include?(observer)
        end

        true
      end

      def detach(args)
        Utils::Arrays.flatten_and_compact(args).each do |observer|
          delete_observer(observer)
        end

        true
      end

      def on(options)
        on!(options, once: false)
      end

      EventNameToCall = -> event_name { -> subscriber { subscriber[0] == :callable && subscriber[1] == event_name } }

      def off(args)
        Utils::Arrays.flatten_and_compact(args).each do |value|
          if value.is_a?(Symbol)
            @relation.delete_if(&EventNameToCall[value])
          else
            delete_observer(value)
          end
        end
      end

      def once(options)
        on!(options, once: true)
      end

      def delete(observers)
        return if observers.empty?

        observers.each { |observer| @relation.delete(observer) }
      end

      private

        def delete_observer(observer)
          @relation.delete_if(&EqualTo[observer])
        end

        def on!(options, once:)
          event, callable, with, context = options[:event], options[:call], options[:with], options[:context]

          return true unless event.is_a?(Symbol) && callable.respond_to?(:call)

          @relation << [:callable, event, [callable, with, context], once] unless include?(callable)

          true
        end

      private_constant :EqualTo, :EventNameToCall
      private_constant :GetObserver, :MapObserver, :MapObserverWithoutContext
    end

    private_constant :Subscribers
  end
end
