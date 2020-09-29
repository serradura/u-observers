require 'test_helper'

class Micro::ObserversTest < Minitest::Test
  def setup
    StreamInMemory.history.clear
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

  def test_the_observer_notification
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

  def test_the_observer_notification_including_a_context
    Post.transaction do
      post = Post.new(title: 'Hello world')
      post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'Test 1' })
      post.save
    end

    assert_equal("Title: Hello world", StreamInMemory.history[0])
    assert_equal("Title: Hello world, from: Test 1", StreamInMemory.history[1])
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
end
