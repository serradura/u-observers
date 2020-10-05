# frozen_string_literal: true

module Micro
  module Observers
    module For
      require 'micro/observers/for/active_model'

      module ActiveRecord
        def self.included(base)
          base.send(:include, ::Micro::Observers::For::ActiveModel)
        end
      end

    end
  end
end
