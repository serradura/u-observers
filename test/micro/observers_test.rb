require 'test_helper'

class Micro::ObserversTest < Minitest::Test
  def setup
    FakePrinter.history.clear
  end

  def test_that_it_has_a_version_number
    refute_nil ::Micro::Observers::VERSION
  end

  class Post < ActiveRecord::Base
    include ::Micro::Observers

    after_commit \
      &call_observers(action: [:print_title, :print_title_with_data])
  end

  class Book < ActiveRecord::Base
    include ::Micro::Observers

    after_commit(&notify_observers(:transaction_completed))
  end

  module TitlePrinter
    def self.print_title(post)
      FakePrinter.puts("Title: #{post.title}")
    end

    def self.print_title_with_data(post, data)
      FakePrinter.puts("Title: #{post.title}, from: #{data[:from]}")
    end
  end

  module LogTheBookCreation
    def self.transaction_completed(book)
      FakePrinter.puts("The book was successfully created! Title: #{book.title}")
    end
  end

  def test_the_observer_execution_using_the_call_method
    assert_equal(0, FakePrinter.history.size)

    Post.transaction do
      post = Post.new(title: 'Hello world')
      post.observers.attach(TitlePrinter, data: { from: 'Test 1' })
      post.save
    end

    assert_equal("Title: Hello world", FakePrinter.history[0])
    assert_equal("Title: Hello world, from: Test 1", FakePrinter.history[1])
  end

  def test_the_observer_execution_using_the_notify_method
    assert_equal(0, FakePrinter.history.size)

    Book.transaction do
      book = Book.new(title: 'Observers')
      book.observers.attach(LogTheBookCreation)
      book.save
    end

    assert_equal(
      "The book was successfully created! Title: Observers",
      FakePrinter.history[0]
    )
  end

  def test_an_observer_deletion
    Book.transaction do
      book = Book.new(title: 'Observers')
      book.observers.attach(TitlePrinter, data: { from: 'Test 2' })
      book.observers.detach(TitlePrinter)
      book.save
    end

    assert_predicate(FakePrinter.history, :empty?)
  end

  class Person
    include Micro::Observers

    attr_reader :name

    def initialize(name:)
      @name = name
    end

    def name=(new_name)
      changed = new_name != name

      @name = new_name

      observers.notify(:name_has_been_changed) and return if changed
    end
  end

  PrintPersonName = -> (data) do
    FakePrinter.puts("Person name: #{data.fetch(:person).name}, number: #{data.fetch(:number)}")
  end

  def test_observers_caller
    assert_equal(0, FakePrinter.history.size)

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

    assert_equal("Person name: Serradura, number: #{rand_number}", FakePrinter.history[0])
  end
end
