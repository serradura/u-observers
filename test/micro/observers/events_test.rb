require 'test_helper'

module Micro::Observers
  class EventsTest < Minitest::Test
    def test_getting_values
      assert_equal([:call], Events[nil])
      assert_equal([:call], Events[[nil]])
      assert_equal([:a], Events[[:a]])
      assert_equal([:a, :b], Events[[:a, :b]])
      assert_equal([:a, :b], Events[[[:a, :b]]])
      assert_equal([:a, :b], Events[[[:a], :b]])
      assert_equal([:a, :b], Events[[[:a], [:b]]])
    end
  end
end
