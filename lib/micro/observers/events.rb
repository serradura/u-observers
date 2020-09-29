# frozen_string_literal: true

module Micro
  module Observers

    module Events
      DEFAULTS = [:call]

      def self.[](value)
        values = Utils.compact_array(value)

        values.empty? ? DEFAULTS : values
      end

      private_constant :DEFAULTS
    end

  end
end
