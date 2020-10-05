require 'test_helper'

module Micro::Observers
  class EventsTest < Minitest::Test
    def test_getting_values
      assert_equal([], Events[nil])
      assert_equal([], Events[[nil]])
      assert_equal([:a], Events[[:a]])
      assert_equal([:a, :b], Events[[:a, :b]])
      assert_equal([:a, :b], Events[[[:a, :b]]])
      assert_equal([:a, :b], Events[[[:a], :b]])
      assert_equal([:a, :b], Events[[[:a], [:b]]])

      # --

      assert_equal([:call], Events[[], default: [:call]])
      assert_equal([:call], Events[nil, default: [:call]])
      assert_equal([:call], Events[[nil], default: [:call]])
    end

    def test_fetching_values
      assert_equal([:a], Events.fetch([:a]))
      assert_equal([:a, :b], Events.fetch([:a, :b]))
      assert_equal([:a, :b], Events.fetch([[:a, :b]]))
      assert_equal([:a, :b], Events.fetch([[:a], :b]))
      assert_equal([:a, :b], Events.fetch([[:a], [:b]]))

      # --

      [[], nil, [nil]].each do |no_events|
        err = assert_raises(ArgumentError) { Events.fetch(no_events) }
        assert_equal('no events (expected at least 1)', err.message)
      end
    end
  end
end
