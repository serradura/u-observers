require 'test_helper'

module Micro::Observers
  class VersionTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Micro::Observers::VERSION
    end
  end
end
