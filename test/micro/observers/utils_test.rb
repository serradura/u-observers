require 'test_helper'

module Micro::Observers
  class UtilsTest < Minitest::Test
    def test_compact_array
      assert_equal([], Utils::Arrays.flatten_and_compact([]))
      assert_equal([], Utils::Arrays.flatten_and_compact(nil))
      assert_equal([], Utils::Arrays.flatten_and_compact([nil]))
      assert_equal([1], Utils::Arrays.flatten_and_compact([1]))
      assert_equal([1, 2], Utils::Arrays.flatten_and_compact([1, 2]))
      assert_equal([1, 2], Utils::Arrays.flatten_and_compact([[1, 2]]))
      assert_equal([1, 2], Utils::Arrays.flatten_and_compact([[1], 2]))
      assert_equal([1, 2], Utils::Arrays.flatten_and_compact([[1], [2]]))
    end
  end
end
