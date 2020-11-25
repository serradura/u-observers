require 'tempfile'
require 'securerandom'
require 'test_helper'

module Micro::Observers
  class SetOnAndOnceTest < Minitest::Test
    class FileManager
      include Micro::Observers
    end

    RemoveFile = -> file { File.delete(file) }
    PrintFilename = -> file { MemoryOutput.puts(File.basename(file)) }

    def create_file(file_manager, attach_callable_using:, content:)
      Tempfile.open("#{SecureRandom.hex}.txt") { |f| f.puts(content); f }.tap do |file|
        file_manager.observers.public_send(attach_callable_using, event: :remove_file, call: RemoveFile, with: file)
        file_manager.observers.public_send(attach_callable_using, event: :print_filename, call: PrintFilename, with: file)
      end
    end

    def setup
      MemoryOutput.clear
    end

    def test_that_you_can_add_multiple_callables_to_the_same_event_using_the_on_method
      file_manager = FileManager.new

      file1 = create_file(file_manager, attach_callable_using: :on, content: 'foo')
      file2 = create_file(file_manager, attach_callable_using: :on, content: 'bar')

      assert File.exist?(file1.path)
      assert File.exist?(file2.path)

      file_manager.observers.notify!(:print_filename, :remove_file)

      assert_equal(2, MemoryOutput.size)
      assert_equal(4, file_manager.observers.count)

      refute File.exist?(file1.path)
      refute File.exist?(file2.path)
    end

    def test_that_you_can_add_multiple_callables_to_the_same_event_using_the_once_method
      file_manager = FileManager.new

      file1 = create_file(file_manager, attach_callable_using: :once, content: 'foo')
      file2 = create_file(file_manager, attach_callable_using: :once, content: 'bar')

      assert File.exist?(file1.path)
      assert File.exist?(file2.path)

      file_manager.observers.notify!(:print_filename, :remove_file)

      assert_equal(0, file_manager.observers.count)

      refute File.exist?(file1.path)
      refute File.exist?(file2.path)
    end

    def test_the_methods_with_blocks
      subject = { number: 0 }

      observers = Micro::Observers::Set.new(subject)

      observers.on(:add_one) do |event|
        assert_instance_of(Micro::Observers::Event, event)

        event.subject[:number] += 1
      end

      observers.once(:add_two) do |event|
        assert_instance_of(Micro::Observers::Event, event)

        event.subject[:number] += 2
      end

      observers.notify!(:add_one)
      observers.notify!(:add_one)
      observers.notify!(:add_one)
      observers.notify!(:add_two)
      observers.notify!(:add_two)

      assert_equal(5, subject[:number])
    end
  end
end
