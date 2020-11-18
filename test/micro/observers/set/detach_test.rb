require 'test_helper'

module Micro::Observers
  class SetDetachTest < Minitest::Test
    def setup
      MemoryOutput.clear
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
      MemoryOutput.puts("Person name: #{person.name}}")
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

      assert_predicate(MemoryOutput.history, :empty?)
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

      assert_predicate(MemoryOutput.history, :empty?)
    end

    def test_the_detaching_using_off
      person = Person.new(name: 'Rodrigo')

      # --

      person.observers.attach(PersonNamePrinter)
      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(2, person.observers.count)

      person.observers.off(:name_has_been_changed)
      assert_equal(1, person.observers.count)

      assert person.observers.include?(PersonNamePrinter)

      person.observers.off(PersonNamePrinter)

      assert_equal(0, person.observers.count)

      # --

      person.observers.attach(PersonNamePrinter)
      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(2, person.observers.count)

      person.observers.off(:name_has_been_changed, PersonNamePrinter)
      assert_equal(0, person.observers.count)

      # --

      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(1, person.observers.count)

      person.observers.off([:name_has_been_changed])

      assert_equal(0, person.observers.count)

      # --

      person.observers.attach(PersonNamePrinter)
      person.observers.on(event: :name_has_been_changed, call: PrintPersonName)

      assert_equal(2, person.observers.count)

      person.observers.off([:name_has_been_changed, PersonNamePrinter])

      assert_equal(0, person.observers.count)
    end
  end
end
