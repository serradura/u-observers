# frozen_string_literal: true

require 'set'

module Micro
  module Observers

    module Broadcast
      extend self

      def call(subscribers, subject, data, event_names)
        subscribers_list = subscribers.list
        subscribers_to_be_deleted = ::Set.new

        event_names.each(&BroadcastWith[subscribers_list, subject, data, subscribers_to_be_deleted])

        subscribers_to_be_deleted.each { |subscriber| subscribers_list.delete(subscriber) }
      end

      private

        BroadcastWith = -> (subscribers, subject, data, subscribers_to_be_deleted) do
          -> (event_name) do
            subscribers.each do |subscriber|
              notified = NotifySubscriber.(subscriber, subject, data, event_name)
              perform_once = subscriber[3]

              subscribers_to_be_deleted.add(subscriber) if notified && perform_once
            end
          end
        end

        NotifySubscriber = -> (subscriber, subject, data, event_name) do
          NotifyObserver.(subscriber, subject, data, event_name) ||
          NotifyCallable.(subscriber, subject, data, event_name) ||
          false
        end

        NotifyObserver = -> (subscriber, subject, data, event_name) do
          strategy, observer, context = subscriber

          return unless strategy == :observer && observer.respond_to?(event_name)

          event = Event.new(event_name, subject, context, data)

          handler = observer.is_a?(Proc) ? observer : observer.method(event.name)
          handler.arity == 1 ? handler.call(event.subject) : handler.call(event.subject, event)

          true
        end

        NotifyCallable = -> (subscriber, subject, data, event_name) do
          strategy, observer, options = subscriber

          return unless strategy == :callable && observer == event_name

          callable, with, context = options[0], options[1], options[2]

          return callable.call(with) if with && !with.is_a?(Proc)

          event = Event.new(event_name, subject, context, data)

          callable.call(with.is_a?(Proc) ? with.call(event) : event)

          true
        end

      private_constant :BroadcastWith, :NotifySubscriber, :NotifyCallable, :NotifyObserver
    end

    private_constant :Broadcast
  end
end
