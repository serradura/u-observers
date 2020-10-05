require 'test_helper'

module Micro::Observers
  class EventNamesTest < Minitest::Test
    def test_getting_values
      assert_equal([], Event::Names[nil])
      assert_equal([], Event::Names[[nil]])
      assert_equal([:a], Event::Names[[:a]])
      assert_equal([:a, :b], Event::Names[[:a, :b]])
      assert_equal([:a, :b], Event::Names[[[:a, :b]]])
      assert_equal([:a, :b], Event::Names[[[:a], :b]])
      assert_equal([:a, :b], Event::Names[[[:a], [:b]]])

      # --

      assert_equal([:call], Event::Names[[], default: [:call]])
      assert_equal([:call], Event::Names[nil, default: [:call]])
      assert_equal([:call], Event::Names[[nil], default: [:call]])
    end

    def test_fetching_values
      assert_equal([:a], Event::Names.fetch([:a]))
      assert_equal([:a, :b], Event::Names.fetch([:a, :b]))
      assert_equal([:a, :b], Event::Names.fetch([[:a, :b]]))
      assert_equal([:a, :b], Event::Names.fetch([[:a], :b]))
      assert_equal([:a, :b], Event::Names.fetch([[:a], [:b]]))

      # --

      [[], nil, [nil]].each do |no_events|
        err = assert_raises(ArgumentError) { Event::Names.fetch(no_events) }
        assert_equal('no events (expected at least 1)', err.message)
      end
    end
  end
end
