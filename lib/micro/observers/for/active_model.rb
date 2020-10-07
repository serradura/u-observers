# frozen_string_literal: true

module Micro
  module Observers
    module For

      module ActiveModel
        module ClassMethods
          def __notify_observers!(events)
            proc do |object|
              object.observers.subject_changed!
              object.observers.send(:broadcast_if_subject_changed, events)
            end
          end

          INVALID_ARGS_TO_NOTIFY_OBSERVERS_ON_CALLBACK =
            'expected one or more observers and its callback option. e.g. ' \
            'notify_observers(ObserverA, ObserverB, on: :after_commit)'

          def __notify_observers_on_callback(args)
            if (options = args.pop) && args.none?
              raise ArgumentError, INVALID_ARGS_TO_NOTIFY_OBSERVERS_ON_CALLBACK
            else
              callback_name = options.delete(:event)
              callback_args = [callback_name]
              callback_args << options unless options.empty?

              self.public_send(*callback_args) do |object|
                object.observers.attach(args)
                object.observers.subject_changed!
                object.observers.notify(callback_name)
              end
            end
          end

          def notify_observers(*args)
            args = Utils.compact_array(args)

            return __notify_observers_on_callback(args) if args.last.is_a?(Hash)

            __notify_observers!(Event::Names.fetch(args))
          end

          def notify_observers_on(*callback_names)
            Utils.compact_array(callback_names).each do |callback_name|
              self.public_send(callback_name, &__notify_observers!([callback_name]))
            end
          end

          private_constant :INVALID_ARGS_TO_NOTIFY_OBSERVERS_ON_CALLBACK
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.send(:private_class_method, :__notify_observers!, :__notify_observers_on_callback)
          base.send(:include, ::Micro::Observers)
        end
      end
    end
  end
end
