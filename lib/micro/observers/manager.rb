# frozen_string_literal: true

module Micro
  module Observers

    class Manager
      EMPTY_HASH = {}.freeze

      def initialize(list = nil)
        @list = (list.kind_of?(Array) ? list : []).flatten.tap(&:compact!)
      end

      def attach(observer, options = EMPTY_HASH)
        if options[:allow_duplication] || @list.none? { |obs, _data| obs == observer }
          @list << [observer, options[:data]]
        end

        self
      end

      def detach(observer)
        @list.delete_if { |obs, _data| obs == observer }

        self
      end

      def call(subject, action: :call)
        @list.each do |observer, data|
          next unless observer.respond_to?(action)

          handler = observer.method(action)

          case handler.arity
          when 2 then handler.call(subject, data)
          when 1 then handler.call(subject)
          else raise NotImplementedError
          end
        end

        self
      end

      alias notify call

      private_constant :EMPTY_HASH
    end

  end
end
