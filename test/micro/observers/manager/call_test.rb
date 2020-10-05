require 'test_helper'

module Micro::Observers
  class ManagerCallTest < Minitest::Test
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

      observers.call
      observers.call(:word_has_been_changed)

      assert_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call
      observers.call(:word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD'], StreamInMemory.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:word_has_been_changed)
      observers.call

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

      observers.call
      observers.call(:word_has_been_changed)

      assert_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:call, :word_has_been_changed)
      observers.call(:call, :word_has_been_changed)

      refute observers.subject_changed?

      assert_equal(['world', 'WORLD', 'WORLD'], StreamInMemory.history)

      # --

      observers.subject_changed!

      assert observers.subject_changed?

      observers.call(:word_has_been_changed, :call)
      observers.call(:word_has_been_changed, :call)

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

      assert_instance_of(Manager, observers.call!)

      observers.call!(:word_has_been_changed)

      refute_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.call!(:word_has_been_changed)
      observers.call!

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

      observers.call!(:call, :word_has_been_changed)

      refute_predicate(StreamInMemory.history, :empty?)

      word.replace('world')

      # --

      refute observers.subject_changed?

      observers.call!(:word_has_been_changed, :call)

      assert_equal(
        ['world', 'HELLO', 'HELLO', 'WORLD', 'world', 'WORLD'],
        StreamInMemory.history
      )
    end
  end
end
