# frozen_string_literal: true

module Micro
  module Observers

    class Event
      require 'micro/observers/event/names'

      attr_reader :name, :subject, :context, :data

      def initialize(name, subject, context, data)
        @name, @subject = name, subject
        @context, @data = context, data
      end

      alias ctx context
      alias subj subject
    end

  end
end
