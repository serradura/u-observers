# frozen_string_literal: true

module Micro
  module Observers

    module Events
      def self.[](value, default: Utils::EMPTY_ARRAY)
        values = Utils.compact_array(value)

        values.empty? ? default : values
      end

      NO_EVENTS_MSG = 'no events (expected at least 1)'.freeze

      def self.fetch(value)
        values = self[value]

        return values unless values.empty?

        raise ArgumentError, NO_EVENTS_MSG
      end

      private_constant :NO_EVENTS_MSG
    end

  end
end
