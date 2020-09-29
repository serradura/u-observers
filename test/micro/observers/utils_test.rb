require 'test_helper'

module Micro::Observers
  class UtilsTest < Minitest::Test
    def test_compact_array
      assert_equal([], Utils.compact_array([]))
      assert_equal([], Utils.compact_array(nil))
      assert_equal([], Utils.compact_array([nil]))
      assert_equal([1], Utils.compact_array([1]))
      assert_equal([1, 2], Utils.compact_array([1, 2]))
      assert_equal([1, 2], Utils.compact_array([[1, 2]]))
      assert_equal([1, 2], Utils.compact_array([[1], 2]))
      assert_equal([1, 2], Utils.compact_array([[1], [2]]))
    end
  end
end
