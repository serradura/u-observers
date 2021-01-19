require 'test_helper'

if ENV.fetch('ACTIVERECORD_VERSION', '6.2') < '6.2'
  class Micro::Observers::For::ActiveRecordTest < Minitest::Test
    def setup
      MemoryOutput.clear
    end

    class Book < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_on(:after_commit)
    end

    module LogTheBookCreation
      def self.after_commit(book)
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

      notify_observers_on(:after_commit)
    end

    module TitlePrinter
      def self.after_commit(post)
        MemoryOutput.puts("Title: #{post.title}")
      end
    end

    module TitlePrinterWithContext
      def self.after_commit(post, event)
        MemoryOutput.puts("Title: #{post.title}, from: #{event.context[:from]}")
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
        ], MemoryOutput.history
      )
    end
  end
end
