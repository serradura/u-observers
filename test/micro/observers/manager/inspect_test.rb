require 'test_helper'

module Micro::Observers
  class ManagerInspectTest < Minitest::Test
    PrintWord = -> word { StreamInMemory.puts(word) }

    module PrintUpcasedWord
      def self.call(word)
        StreamInMemory.puts(word.upcase)
      end
    end

    def test_the_observers_inspect_output_when_it_has_subscribers
      observers = Manager.new('hello', subscribers: [PrintWord, PrintUpcasedWord])

      assert_match(
        /<#Micro::Observers::Manager @subject=hello @subject_changed=false @subscribers=\[#<Proc:0x.+\/.+\/inspect_test.rb:5 \(lambda\)>, .+PrintUpcasedWord\]>/,
        observers.inspect
      )
    end

    def test_the_observers_inspect_output_when_it_has_no_subscribers
      observers = Manager.new('hello')

      assert_match(
        /<#Micro::Observers::Manager @subject=hello @subject_changed=false @subscribers=\[\]>/,
        observers.inspect
      )
    end
  end
end
