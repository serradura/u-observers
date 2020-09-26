# frozen_string_literal: true

module Micro
  module Observers

    module Utils
      EMPTY_HASH = {}.freeze

      def self.compact_array(value)
        Array(value).flatten.tap(&:compact!)
      end
    end

  end
end
