require 'test_helper'

module Micro::Observers
  class ManagerNotifyTest < Minitest::Test
    def setup
      StreamInMemory.history.clear
    end

    module PrintWord
      def self.call(word)
        StreamInMemory.puts(word)
      end
    end

    module PrintUpcasedWord
      def self.call(word)
        StreamInMemory.puts(word.upcase)
      end

      singleton_class.send(:alias_method, :word_has_been_changed, :call)
    end

    def test_the_idempotency_with_single_notifications
      word = 'hello'

      observers = Manager.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.notify(:call)
      observers.notify(:word_has_been_changed)

      assert_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.notify(:call)
      observers.notify(:word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD'], StreamInMemory.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.notify(:word_has_been_changed)
      observers.notify(:call)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD', 'WORLD'], StreamInMemory.history)
    end

    def test_the_idempotency_with_multiple_notifications
      word = 'hello'

      observers = Manager.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.notify(:call)
      observers.notify(:word_has_been_changed)

      assert_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.notify(:call, :word_has_been_changed)
      observers.notify(:call, :word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD', 'WORLD'], StreamInMemory.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.notify(:word_has_been_changed, :call)
      observers.notify(:word_has_been_changed, :call)

      refute observers.subject_changed?

      assert_equal(
        ['world', 'WORLD', 'WORLD', 'WORLD', 'world', 'WORLD'],
        StreamInMemory.history
      )
    end

    def test_no_idempotency_when_calling_single_events
      word = 'hello'

      observers = Manager.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      assert_instance_of(Manager, observers.notify!(:call))

      observers.notify!(:word_has_been_changed)

      refute_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.notify!(:word_has_been_changed)
      observers.notify!(:call)

      assert_equal(
        ['world', 'HELLO', 'HELLO', 'WORLD', 'world', 'WORLD'],
        StreamInMemory.history
      )
    end

    def test_no_idempotency_when_calling_multiple_events
      word = 'hello'

      observers = Manager.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      observers.notify!(:call, :word_has_been_changed)

      refute_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.notify!(:word_has_been_changed, :call)

      assert_equal(
        ['world', 'HELLO', 'HELLO', 'WORLD', 'world', 'WORLD'],
        StreamInMemory.history
      )
    end

    def test_that_the_notify_methods_require_at_least_one_event
      observers = Manager.new('hello')

      err1 = assert_raises(ArgumentError) { observers.notify }
      assert_equal('no events (expected at least 1)', err1.message)

      err2 = assert_raises(ArgumentError) { observers.notify(nil) }
      assert_equal('no events (expected at least 1)', err2.message)

      # --

      err3 = assert_raises(ArgumentError) { observers.notify! }
      assert_equal('no events (expected at least 1)', err3.message)

      err4 = assert_raises(ArgumentError) { observers.notify!(nil) }
      assert_equal('no events (expected at least 1)', err4.message)

      # --

      observers.notify(:something_happened)
      observers.notify!(:something_happened)
    end
  end
end
