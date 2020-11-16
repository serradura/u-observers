# frozen_string_literal: true

require 'set'

module Micro
  module Observers

    module Broadcast
      extend self

      def call(data, subject, event_names, subscribers)
        sweep_marker = ::Set.new

        event_names.each(&BroadcastWith[subscribers, subject, data, sweep_marker])

        sweep_marker.each { |subscriber| subscribers.delete(subscriber) }
      end

      private

        BroadcastWith = -> (subscribers, subject, data, sweep_marker) do
          -> (event_name) do
            subscribers.each do |subscriber|
              notified = Notify.(subscriber, event_name, subject, data)

              sweep_marker << subscriber if notified && subscriber[3]
            end
          end
        end

        Notify = -> (subscriber, event_name, subject, data) do
          NotifyObserver.(subscriber, event_name, subject, data) ||
          NotifyCallable.(subscriber, event_name, subject, data) ||
          false
        end

        NotifyObserver = -> (subscriber, event_name, subject, data) do
          strategy, observer, context = subscriber

          return unless strategy == :observer && observer.respond_to?(event_name)

          event = Event.new(event_name, subject, context, data)

          handler = observer.is_a?(Proc) ? observer : observer.method(event.name)
          handler.arity == 1 ? handler.call(event.subject) : handler.call(event.subject, event)

          true
        end

        NotifyCallable = -> (subscriber, event_name, subject, data) do
          strategy, observer, opt = subscriber

          return unless strategy == :callable && observer == event_name

          callable, with, context = opt[0], opt[1], opt[2]

          return callable.call(with) if with && !with.is_a?(Proc)

          event = Event.new(event_name, subject, context, data)

          callable.call(with.is_a?(Proc) ? with.call(event) : event)

          true
        end
    end

    private_constant :Broadcast
  end
end
