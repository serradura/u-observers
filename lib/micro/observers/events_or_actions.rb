# frozen_string_literal: true

module Micro
  module Observers

    module EventsOrActions
      DEFAULTS = [:call]

      def self.[](value)
        values = Utils.compact_array(value)

        values.empty? ? DEFAULTS : values
      end

      def self.fetch_actions(hash)
        return self[hash.fetch(:actions) { hash.fetch(:action) }] if hash.is_a?(Hash)

        raise ArgumentError, 'expected a hash with the key :action or :actions'
      end

      private_constant :DEFAULTS
    end

  end
end
