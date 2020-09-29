require 'test_helper'

class Micro::ObserversTest < Minitest::Test
  def setup
    StreamInMemory.history.clear
  end

  def test_that_it_has_a_version_number
    refute_nil ::Micro::Observers::VERSION
  end

  class Post < ActiveRecord::Base
    include ::Micro::Observers

    after_commit(&notify_observers(:record_has_been_persisted))
  end

  module TitlePrinter
    def self.record_has_been_persisted(post)
      StreamInMemory.puts("Title: #{post.title}")
    end
  end

  module TitlePrinterWithContext
    def self.record_has_been_persisted(post, context)
      StreamInMemory.puts("Title: #{post.title}, from: #{context[:from]}")
    end
  end

  def test_the_notification_using_multiple_observers
    Post.transaction do
      post = Post.new(title: 'Hello world')
      post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'Test 1' })
      post.save
    end

    assert_equal("Title: Hello world", StreamInMemory.history[0])
    assert_equal("Title: Hello world, from: Test 1", StreamInMemory.history[1])
  end

  class Book < ActiveRecord::Base
    include ::Micro::Observers

    after_commit(&notify_observers(:transaction_completed))
  end

  module LogTheBookCreation
    def self.transaction_completed(book)
      StreamInMemory.puts("The book was successfully created! Title: #{book.title}")
    end
  end

  def test_the_observer_execution_using_the_notify_method
    Book.transaction do
      book = Book.new(title: 'Observers')
      book.observers.attach(LogTheBookCreation)
      book.save
    end

    assert_equal(
      "The book was successfully created! Title: Observers",
      StreamInMemory.history[0]
    )
  end

  class Person
    include Micro::Observers

    attr_reader :name

    def initialize(name:)
      @name = name
    end

    def name=(new_name)
      observers.subject_changed(new_name != name)

      @name = new_name

      observers.notify(:name_has_been_changed)
    end
  end

  PrintPersonName = -> (data) do
    StreamInMemory.puts("Person name: #{data.fetch(:person).name}, number: #{data.fetch(:number)}")
  end

  def test_observers_caller
    rand_number = rand

    person = Person.new(name: 'Rodrigo')
    person.observers.on(
      event: :name_has_been_changed,
      call: PrintPersonName,
      with: -> person do
        { person: person, number: rand_number }
      end
    )

    person.name = 'Serradura'

    assert_equal("Person name: Serradura, number: #{rand_number}", StreamInMemory.history[0])
  end

  class Doer1
    def do_a(_); StreamInMemory.puts('do_a 1') ;end
    def do_b(_); StreamInMemory.puts('do_b 1') ;end
  end

  class Doer2
    def do_b(_); StreamInMemory.puts('do_b 2') ;end
  end

  def test_calling_actions
    doer1, doer2 = Doer1.new, Doer2.new

    person = Person.new(name: 'Rodrigo')

    # -

    person.observers.attach(doer1, doer2)

    # -

    person.observers.call(:do_a)

    assert_equal(1, StreamInMemory.history.size)

    person.observers.call([:do_b])

    assert_equal(3, StreamInMemory.history.size)

    person.observers.call([:do_a, :do_b])

    assert_equal(6, StreamInMemory.history.size)

    person.observers.call(:do_a, :do_b)

    assert_equal(9, StreamInMemory.history.size)

    assert_equal(
      ['do_a 1', 'do_b 1', 'do_b 2', 'do_a 1', 'do_b 1', 'do_b 2', 'do_a 1', 'do_b 1', 'do_b 2'],
      StreamInMemory.history
    )

    # --

    person.observers.detach(doer1, doer2)

    person.observers.call(actions: [:do_a, :do_b])

    assert_equal(9, StreamInMemory.history.size)
  end
end
