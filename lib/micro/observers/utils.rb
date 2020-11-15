# frozen_string_literal: true

module Micro
  module Observers

    module Utils
      EMPTY_HASH = {}.freeze

      module Arrays
        def self.fetch_from_args(args)
          args.size == 1 && (first = args[0]).is_a?(::Array) ? first : args
        end

        def self.flatten_and_compact(value)
          return [] unless value

          array = Array(value).flatten
          array.compact!
          array
        end
      end
    end

  end
end
