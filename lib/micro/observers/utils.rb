# frozen_string_literal: true

module Micro
  module Observers

    module Utils
      module Arrays
        def self.flatten_and_compact(value)
          Array(value).flatten.tap(&:compact!)
        end
      end
    end

  end
end
