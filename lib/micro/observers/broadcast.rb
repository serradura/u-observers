# frozen_string_literal: true

module Micro
  module Observers

    module Broadcast
      extend self

      def call(observers, event_names, data, if_subject_changed: false)
        return call_if_subject_changed(observers, event_names, data) if if_subject_changed

        call!(observers, event_names, data)
      end

      private

        def call_if_subject_changed(observers, event_names, data = nil)
          return unless observers.subject_changed?

          call!(observers, event_names, data)

          observers.subject_changed(false)
        end

        def call!(observers, event_names, data)
          return if observers.none?

          subject = observers.__subject__

          event_names.each do |event_name|
            observers.__each__(&NotifyWith[event_name, subject, data])
          end
        end

        NotifyWith = -> (event_name, subject, data) do
          -> observer_data do
            strategy, observer, context = observer_data

            if strategy == :observer && observer.respond_to?(event_name)
              event = Event.new(event_name, subject, context, data)

              return NotifyHandler.(observer, event)
            end

            if strategy == :callable && observer == event_name
              return NotifyCallable.(event_name, subject, context, data)
            end
          end
        end

        NotifyHandler = -> (observer, event) do
          handler = observer.is_a?(Proc) ? observer : observer.method(event.name)

          return handler.call(event.subject) if handler.arity == 1

          handler.call(event.subject, event)
        end

        NotifyCallable = -> (event_name, subject, opt, data) do
          callable, with, context = opt[0], opt[1], opt[2]

          return callable.call(with) if with && !with.is_a?(Proc)

          event = Event.new(event_name, subject, context, data)

          callable.call(with.is_a?(Proc) ? with.call(event) : event)
        end

      private_constant :NotifyWith, :NotifyHandler, :NotifyCallable
    end

  end
end
