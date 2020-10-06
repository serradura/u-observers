require 'test_helper'

module Micro::Observers
  class SetDetachTest < Minitest::Test
    def setup
      StreamInMemory.history.clear
    end

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

    def test_the_detaching_of_one_observer_per_time
      person = Person.new(name: 'Rodrigo')
      person.observers.attach(PersonNamePrinter)

      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(2, person.observers.count)
      assert_predicate(person.observers, :some?)

      assert_instance_of(Set, person.observers.detach(PersonNamePrinter))

      assert_equal(1, person.observers.count)

      person.observers.detach(PrintPersonName)

      assert_equal(0, person.observers.count)
      assert_predicate(person.observers, :none?)

      person.name = 'Serradura'

      assert_predicate(StreamInMemory.history, :empty?)
    end

    def test_the_detaching_of_multiples_observers
      person = Person.new(name: 'Rodrigo')
      person.observers.attach(PersonNamePrinter)
      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(2, person.observers.count)
      assert_predicate(person.observers, :some?)

      person.observers.detach(PersonNamePrinter, PrintPersonName)

      assert_equal(0, person.observers.count)
      assert_predicate(person.observers, :none?)

      person.name = 'Serradura'

      assert_predicate(StreamInMemory.history, :empty?)
    end
  end
end
