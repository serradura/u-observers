# frozen_string_literal: true

module Micro
  module Observers

    class Subscribers
      EqualTo = -> (observer) { -> subscriber { GetObserver[subscriber] == observer } }
      GetObserver = -> subscriber { subscriber[0] == :observer ? subscriber[1] : subscriber[2][0] }
      MapObserver = -> (observer, options) { [:observer, observer, options[:context]] }
      MapObserverWithoutContext = -> observer { MapObserver[observer, Utils::EMPTY_HASH] }

      attr_reader :relation

      def initialize(arg)
        array = Utils::Arrays.flatten_and_compact(arg.kind_of?(Array) ? arg : [])
        @relation = array.map(&MapObserverWithoutContext)
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

        Utils::Arrays.flatten_and_compact(args).each do |observer|
          @relation << MapObserver[observer, options] unless include?(observer)
        end

        true
      end

      def detach(args)
        Utils::Arrays.flatten_and_compact(args).each do |observer|
          @relation.delete_if(&EqualTo[observer])
        end

        true
      end

      def on(options)
        event, callable, with, context = options[:event], options[:call], options[:with], options[:context]

        return true unless event.is_a?(Symbol) && callable.respond_to?(:call)

        @relation << [:callable, event, [callable, with, context]] unless include?(callable)

        true
      end

      def to_inspect
        none? ? @relation : @relation.map(&GetObserver)
      end

      private_constant :EqualTo, :GetObserver, :MapObserver, :MapObserverWithoutContext
    end

  end
end
