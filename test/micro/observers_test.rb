require 'test_helper'


class Micro::ObserversTest < Minitest::Test
  def setup
    MemoryOutput.clear
  end

  if ENV.fetch('ACTIVERECORD_VERSION', '6.2') < '6.2'
    class Book < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      after_commit(&notify_observers(:transaction_completed))
    end

    module LogTheBookCreation
      def self.transaction_completed(book)
        MemoryOutput.puts("The book was successfully created! Title: #{book.title}")
      end
    end

    def test_the_observer_notification
      Book.transaction do
        book = Book.new(title: 'Observers')
        book.observers.attach(LogTheBookCreation)
        book.save
      end

      assert_equal(
        ['The book was successfully created! Title: Observers'],
        MemoryOutput.history
      )
    end

    class Post < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      after_commit(&notify_observers(:record_has_been_persisted))
    end

    module TitlePrinterWithContext
      def self.record_has_been_persisted(post, event)
        MemoryOutput.puts("Title: #{post.title}, from: #{event.ctx[:from]}")
      end
    end

    def test_the_observer_notification_including_a_context
      Post.transaction do
        post = Post.new(title: 'Hello world')
        post.observers.on(:record_has_been_persisted) { |event| MemoryOutput.puts("Title: #{event.subject.title}") }
        post.observers.attach(TitlePrinterWithContext, context: { from: 'Test 1' })
        post.save
      end

      assert_equal(
        [
          'Title: Hello world',
          'Title: Hello world, from: Test 1'
        ], MemoryOutput.history
      )
    end
  end

  class Person
    include Micro::Observers

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def name=(new_name)
      return unless observers.subject_changed(new_name != @name)

      @name = new_name

      observers.notify(:name_has_been_changed)
    end
  end

  PrintPersonName = -> (data) do
    MemoryOutput.puts("Person name: #{data.fetch(:person).name}, number: #{data.fetch(:number)}")
  end

  def test_a_callable_observer_without_providing_a_context
    rand_number = rand

    person = Person.new('Rodrigo')
    person.observers.on(
      event: :name_has_been_changed,
      call: PrintPersonName,
      with: -> event { {person: event.subject, number: rand_number} }
    )

    person.name = 'Serradura'

    assert_equal(["Person name: Serradura, number: #{rand_number}"], MemoryOutput.history)
  end

  def test_a_callable_observer_with_a_context
    rand_number = rand

    person = Person.new('Rodrigo')
    person.observers.on(
      event: :name_has_been_changed,
      call: PrintPersonName,
      with: -> event { {person: event.subject, number: event.context} },
      context: rand_number,
    )

    person.name = 'Serradura'

    assert_equal(["Person name: Serradura, number: #{rand_number}"], MemoryOutput.history)
  end
end
