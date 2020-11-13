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
            observers.__each__ do |strategy, observer, context|
              case strategy
              when :observer then notify_observer(subject, observer, event_name, context, data)
              when :callable then notify_callable(subject, observer, event_name, context, data)
              end
            end
          end
        end

        def notify_observer(subject, observer, event_name, context, data)
          return unless observer.respond_to?(event_name)

          handler = observer.is_a?(Proc) ? observer : observer.method(event_name)

          return handler.call(subject) if handler.arity == 1

          handler.call(subject, Event.new(event_name, subject, context, data))
        end

        def notify_callable(subject, expected_event_name, event_name, opt, data)
          return if expected_event_name != event_name

          callable, with, context = opt[0], opt[1], opt[2]
          callable_arg =
            if with && !with.is_a?(Proc)
              with
            else
              event = Event.new(event_name, subject, context, data)

              with.is_a?(Proc) ? with.call(event) : event
            end

          callable.call(callable_arg)
        end
    end

  end
end
