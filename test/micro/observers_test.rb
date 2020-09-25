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
      &call_observers(with: [:print_title, :print_title_with_data])
  end

  class Book < ActiveRecord::Base
    include ::Micro::Observers

    after_commit(&notify_observers(with: [:print_title, :print_title_with_data]))
  end

  module TitlePrinter
    def self.print_title(post)
      FakePrinter.puts("Title: #{post.title}")
    end

    def self.print_title_with_data(post, data)
      FakePrinter.puts("Title: #{post.title}, from: #{data[:from]}")
    end
  end

  def test_the_observer_execution_using_the_call_method
    Post.transaction do
      post = Post.new(title: 'Hello world')
      post.observers.attach(TitlePrinter, data: { from: 'Test 1' })
      post.save
    end

    assert_equal("Title: Hello world", FakePrinter.history[0])
    assert_equal("Title: Hello world, from: Test 1", FakePrinter.history[1])
  end

  def test_the_observer_execution_using_the_notify_method
    Book.transaction do
      book = Book.new(title: 'Observers')
      book.observers.attach(TitlePrinter, data: { from: 'Test 2' })
      book.save
    end

    assert_equal("Title: Observers", FakePrinter.history[0])
    assert_equal("Title: Observers, from: Test 2", FakePrinter.history[1])
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
end
