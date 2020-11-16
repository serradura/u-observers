require 'test_helper'

module Micro::Observers
  class SetNotifyTest < Minitest::Test
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

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

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

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

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

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

      # --

      assert_equal(2, observers.count)
      assert_predicate(observers, :some?)

      refute observers.subject_changed?

      assert_instance_of(Set, observers.notify!(:call))

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

      observers = Set.new(word, subscribers: [PrintWord, PrintUpcasedWord])

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
      observers = Set.new('hello')

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

    module NotificationsForStatusChanging
      def self.canceled(subj)
        StreamInMemory.puts("Object #{subj.object_id} has been canceled")
      end

      def self.status_changed(subj)
        StreamInMemory.puts("Object #{subj.object_id} has its status changed")
      end
    end

    def test_subscriber_that_was_attached_using_once_mode
      object = Object.new

      register_status_changing = -> _evt { StreamInMemory.puts("121211") }
      register_cancelation = -> _evt { StreamInMemory.puts("121212") }

      observers1 = Set.new(object)
      observers1.attach(NotificationsForStatusChanging, perform_once: true)
      observers1.once(event: :canceled, call: register_cancelation)
      observers1.once(event: :status_changed, call: register_status_changing)

      assert_equal(3, observers1.count)
      assert_predicate(observers1, :some?)

      refute observers1.subject_changed?

      observers1.notify!(:status_changed, :canceled)

      assert_equal(0, observers1.count)

      observers1.notify!(:status_changed, :canceled)

      refute_predicate(StreamInMemory.history, :empty?)

      assert_equal(
        [
          "Object #{object.object_id} has its status changed",
          '121211',
          "Object #{object.object_id} has been canceled",
          '121212',
        ],
        StreamInMemory.history
      )
    end
  end
end
