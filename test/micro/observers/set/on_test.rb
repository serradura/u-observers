require 'tempfile'
require 'securerandom'
require 'test_helper'

module Micro::Observers
  class SetOnTest < Minitest::Test
    class FileManager
      include Micro::Observers
    end

    RemoveFile = -> file { File.delete(file) }

    def create_file
      Tempfile.new("#{SecureRandom.hex}.txt")
    end

    def test_that_you_can_add_multiple_callables_to_the_same_event_name
      file1 = create_file
      file2 = create_file

      file_manager = FileManager.new
      file_manager.observers.on(event: :remove_file, call: RemoveFile, with: file1)
      file_manager.observers.on(event: :remove_file, call: RemoveFile, with: file2)

      assert File.exist?(file1.path)
      assert File.exist?(file2.path)

      file_manager.observers.notify!(:remove_file)

      refute File.exist?(file1.path)
      refute File.exist?(file2.path)
    end
  end
end
