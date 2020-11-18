require 'test_helper'

module Micro::Observers
  class SetCallTest < Minitest::Test
    def setup
      MemoryOutput.clear
    end

    module PrintWord
      def self.call(word)
        MemoryOutput.puts(word)
      end
    end

    module PrintUpcasedWord
      def self.call(word)
        MemoryOutput.puts(word.upcase)
      end

      singleton_class.send(:alias_method, :word_has_been_changed, :call)
    end

    def test_the_idempotency_with_single_notifications
      word = 'hello'

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.call
      observers.call(:word_has_been_changed)

      assert_predicate(MemoryOutput.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call
      observers.call(:word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD'], MemoryOutput.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:word_has_been_changed)
      observers.call

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD', 'WORLD'], MemoryOutput.history)
    end

    def test_the_idempotency_with_multiple_notifications
      word = 'hello'

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.call
      observers.call(:word_has_been_changed)

      assert_predicate(MemoryOutput.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:call, :word_has_been_changed)
      observers.call(:call, :word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD', 'WORLD'], MemoryOutput.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:word_has_been_changed, :call)
      observers.call(:word_has_been_changed, :call)

      refute observers.subject_changed?

      assert_equal(
        ['world', 'WORLD', 'WORLD', 'WORLD', 'world', 'WORLD'],
        MemoryOutput.history
      )
    end

    def test_no_idempotency_when_calling_single_events
      word = 'hello'

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      assert_instance_of(Set, observers.call!)

      observers.call!(:word_has_been_changed)

      refute_predicate(MemoryOutput.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.call!(:word_has_been_changed)
      observers.call!

      assert_equal(
        ['world', 'HELLO', 'HELLO', 'WORLD', 'world', 'WORLD'],
        MemoryOutput.history
      )
    end

    def test_no_idempotency_when_calling_multiple_events
      word = 'hello'

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.call!(:call, :word_has_been_changed)

      refute_predicate(MemoryOutput.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.call!(:word_has_been_changed, :call)

      assert_equal(
        ['world', 'HELLO', 'HELLO', 'WORLD', 'world', 'WORLD'],
        MemoryOutput.history
      )
    end

    def test_the_notification_of_a_subscriber_that_was_attached_using_once_mode
      observers1 = Set.new('hello')
      observers1.attach(PrintWord, PrintUpcasedWord, perform_once: true)

      assert_equal(2, observers1.count)
      assert_predicate(observers1, :some?)

      refute observers1.subject_changed?

      observers1.call!

      assert_equal(0, observers1.count)

      observers1.call!

      refute_predicate(MemoryOutput.history, :empty?)

      assert_equal(
        ['hello', 'HELLO'],
        MemoryOutput.history
      )

      # ---

      observers2 = Set.new('world')
      observers2.attach([PrintWord, PrintUpcasedWord], perform_once: true)

      assert_equal(2, observers2.count)
      assert_predicate(observers2, :some?)

      refute observers2.subject_changed?

      observers2.call!

      assert_equal(0, observers2.count)

      observers2.call!

      refute_predicate(MemoryOutput.history, :empty?)

      assert_equal(
        ['hello', 'HELLO', 'world', 'WORLD'],
        MemoryOutput.history
      )

      # ---

      observers3 = Set.new('foo')
      observers3.attach(PrintWord)
      observers3.attach(PrintUpcasedWord, perform_once: true)

      assert_equal(2, observers3.count)
      assert_predicate(observers3, :some?)

      refute observers3.subject_changed?

      observers3.call!

      assert_equal(1, observers3.count)

      observers3.call!

      refute_predicate(MemoryOutput.history, :empty?)

      assert_equal(
        ['hello', 'HELLO', 'world', 'WORLD', 'foo', 'FOO', 'foo'],
        MemoryOutput.history
      )

      # --

      observers4 = Set.new('bar')
      observers4.attach(PrintWord)
      observers4.attach(PrintUpcasedWord, perform_once: true)

      assert_equal(2, observers4.count)
      assert_predicate(observers4, :some?)

      refute observers4.subject_changed?

      observers4.call!(:undefined)

      assert_equal(2, observers4.count)

      observers4.call!(:word_has_been_changed)

      assert_equal(1, observers4.count)

      observers4.call!(:word_has_been_changed)

      refute_predicate(MemoryOutput.history, :empty?)

      assert_equal(
        ['hello', 'HELLO', 'world', 'WORLD', 'foo', 'FOO', 'foo', 'BAR'],
        MemoryOutput.history
      )
    end
  end
end
