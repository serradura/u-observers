# frozen_string_literal: true

module Micro
  module Observers

    class Manager
      EMPTY_HASH = {}.freeze

      SameObserver = -> (observer) do
        -> item { item[0] == :observer && item[1] == observer }
      end

      def self.for(subject)
        new(subject)
      end

      def initialize(subject, list = nil)
        @subject = subject

        @list = (list.kind_of?(Array) ? list : []).flatten.tap(&:compact!)
      end

      def included?(observer)
        @list.any?(&SameObserver[observer])
      end

      def attach(observer, options = EMPTY_HASH)
        if options[:allow_duplication] || !included?(observer)
          @list << [:observer, observer, options[:data]]
        end

        self
      end

      def on(options=EMPTY_HASH)
        action, callable, with = options[:action], options[:call], options[:with]

        return self unless action.is_a?(Symbol) && callable.respond_to?(:call)

        arg = with.is_a?(Proc) ? with.call(@subject) : subject

        @list << [:caller, action, [callable, arg]]
      end

      def detach(observer)
        @list.delete_if(&SameObserver[observer])

        self
      end

      def call(action = :call)
        @list.each do |type, observer, data|
          if type == :caller && observer == action
            data[0].call(data[1])
          elsif type == :observer && observer.respond_to?(action)
            handler = observer.method(action)

            return handler.call(@subject) if handler.arity == 1

            handler.call(@subject, data)
          end
        end

        self
      end

      alias notify call

      private_constant :EMPTY_HASH
    end

  end
end
