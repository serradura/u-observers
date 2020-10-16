# frozen_string_literal: true

module Micro
  module Observers
    module For

      module ActiveModel
        module ClassMethods
          def notify_observers!(events)
            proc do |object|
              object.observers.subject_changed!
              object.observers.send(:broadcast_if_subject_changed, events)
            end
          end

          def notify_observers(*events)
            notify_observers!(Event::Names.fetch(events))
          end

          def notify_observers_on(*callback_methods)
            Utils::Arrays.flatten_and_compact(callback_methods).each do |callback_method|
              self.public_send(callback_method, &notify_observers!([callback_method]))
            end
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.send(:private_class_method, :notify_observers!)
          base.send(:include, ::Micro::Observers)
        end
      end

    end
  end
end
