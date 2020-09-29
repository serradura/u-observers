require 'test_helper'

module Micro::Observers
  class ManagerAttachTest < Minitest::Test
    class Person
      include Micro::Observers

      attr_reader :name

      def initialize(name:)
        @name = name
      end

      def name=(new_name)
        @name = new_name if observers.subject_changed(new_name != name)

        observers.notify(:name_has_been_changed)
      end
    end

    PrintPersonName = -> (person) do
      StreamInMemory.puts("Person name: #{person.name}}")
    end

    module PersonNamePrinter
      def self.name_has_been_changed(person)
        PrintPersonName.call(person)
      end
    end

    def test_the_attaching_of_one_observer_per_time
      person = Person.new(name: 'Rodrigo')

      assert_instance_of(Manager, person.observers.attach(PersonNamePrinter))

      assert_equal(1, person.observers.count)

      person.observers.attach(PersonNamePrinter)

      assert_equal(1, person.observers.count)

      assert_instance_of(
        Manager,
        person.observers.on(event: :name_has_been_changed, call: PrintPersonName)
      )
      assert_equal(2, person.observers.count)

      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)
      assert_equal(2, person.observers.count)
    end

    def test_the_attaching_of_multiples_observers
      person = Person.new(name: 'Rodrigo')

      person.observers.attach(PersonNamePrinter, PrintPersonName)
      assert_equal(2, person.observers.count)

      person.observers.attach(PersonNamePrinter, PrintPersonName)
      assert_equal(2, person.observers.count)
    end

    def test_the_avoidance_of_attaching_an_invalid_subscriber
      person = Person.new(name: 'Rodrigo')

      assert_instance_of(Manager, person.observers.on(event: 'foo', call: -> {}))
      assert_equal(0, person.observers.count)

      assert_instance_of(Manager, person.observers.on(event: :foo, call: nil))
      assert_equal(0, person.observers.count)
    end

    def test_the_handler_argument_definition
      person = Person.new(name: 'Rodrigo')

      person.observers.on(
        event: :name_has_been_changed,
        call: -> subject { assert_instance_of(Person, subject) }
      )

      person.observers.on(
        event: :name_has_been_changed,
        call: -> value { assert_equal(123, value) },
        with: 123
      )

      person.observers.on(
        event: :name_has_been_changed,
        call: -> subject { assert_instance_of(Person, subject) },
        with: nil
      )

      person.observers.on(
        event: :name_has_been_changed,
        call: -> data { assert_equal({person: person}, data) },
        with: -> subject { {person: subject} }
      )

      assert_equal(4, person.observers.count)

      person.observers.on(
        event: :name_has_been_updated,
        call: -> subject { raise }
      )

      assert_equal(5, person.observers.count)

      person.name = 'Serradura'
    end
  end
end
