require 'test_helper'

module Micro::Observers
  class EventTest < Minitest::Test
    PrintPersonName1 = -> (event) do
      event.data.assert_equal('Rodrigo', event.subject)
      event.data.assert_equal(event.subject, event.subj)

      # --

      event.data.assert_instance_of(::Micro::Observers::Event, event)

      event.data.assert_equal(:name_has_been_changed, event.name)

      event.data.assert_nil(event.context)
      event.data.assert_nil(event.ctx)
    end

    PrintPersonName2 = -> (name, event) do
      event.data.assert_equal('Rodrigo', event.subject)
      event.data.assert_equal(event.subject, event.subj)

      # --

      event.data.assert_instance_of(::Micro::Observers::Event, event)

      event.data.assert_equal(:call, event.name)

      event.data.assert_nil(event.context)
      event.data.assert_nil(event.ctx)
    end

    module PersonNamePrinter
      def self.name_has_been_changed(name, event)
        event.ctx.assert_equal('Rodrigo', name)
        event.ctx.assert_equal(name, event.subject)
        event.ctx.assert_equal(event.subject, event.subj)

        event.ctx.assert_instance_of(::Micro::Observers::Event, event)

        event.ctx.assert_equal(:name_has_been_changed, event.name)

        event.ctx.assert_equal(1, event.data)
      end
    end

    def test_the_received_event_scructure
      observers = Micro::Observers::Set.new('Rodrigo')

      # --

      observers.on(event: :name_has_been_changed, call: PrintPersonName1)
      observers.subject_changed!
      observers.notify(:name_has_been_changed, data: self)
      observers.detach(PrintPersonName1)

      assert_predicate(observers, :none?)

      observers.attach(PrintPersonName2)
      observers.subject_changed!
      observers.call(data: self)
      observers.detach(PrintPersonName2)

      assert_predicate(observers, :none?)

      observers.attach(PersonNamePrinter, context: self)
      observers.subject_changed!
      observers.notify(:name_has_been_changed, data: 1)
      observers.detach(PersonNamePrinter)

      assert_predicate(observers, :none?)

      # --

      observers.on(event: :name_has_been_changed, call: PrintPersonName1)
      observers.notify!(:name_has_been_changed, data: self)
      observers.detach(PrintPersonName1)

      assert_predicate(observers, :none?)

      observers.attach(PrintPersonName2)
      observers.call!(data: self)
      observers.detach(PrintPersonName2)

      assert_predicate(observers, :none?)

      observers.attach(PersonNamePrinter, context: self)
      observers.notify!(:name_has_been_changed, data: 1)
      observers.detach(PersonNamePrinter)

      assert_predicate(observers, :none?)
    end
  end
end
