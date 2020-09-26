# frozen_string_literal: true

module Micro
  module Observers

    module EventsOrActions
      DEFAULT = [:call]

      def self.[](values)
        vals = Utils.compact_array(values)

        vals.empty? ? DEFAULT : vals
      end

      private_constant :DEFAULT
    end

  end
end
