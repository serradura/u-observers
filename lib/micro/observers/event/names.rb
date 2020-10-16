# frozen_string_literal: true

module Micro
  module Observers

    class Event::Names
      EMPTY_ARRAY = [].freeze

      def self.[](value, default: EMPTY_ARRAY)
        values = Utils::Arrays.flatten_and_compact(value)

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
