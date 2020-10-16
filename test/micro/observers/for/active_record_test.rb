require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.1') < '6.1'
  class Micro::Observers::For::ActiveRecordTest < Minitest::Test
    def setup
      StreamInMemory.history.clear
    end

    class Book < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_on(:after_commit)
    end

    module LogTheBookCreation
      def self.after_commit(book)
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
        ['The book was successfully created! Title: Observers'],
        StreamInMemory.history
      )
    end

    class Post < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_on(:after_commit)
    end

    module TitlePrinter
      def self.after_commit(post)
        StreamInMemory.puts("Title: #{post.title}")
      end
    end

    module TitlePrinterWithContext
      def self.after_commit(post, event)
        StreamInMemory.puts("Title: #{post.title}, from: #{event.context[:from]}")
      end
    end

    def test_the_observer_notification_including_a_context
      Post.transaction do
        post = Post.new(title: 'Hello world')
        post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'Test 1' })
        post.save
      end

      assert_equal(
        [
          'Title: Hello world',
          'Title: Hello world, from: Test 1'
        ], StreamInMemory.history
      )
    end
  end
end
