require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch if RUBY_VERSION >= '2.5.0'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

if activerecord_version = ENV['ACTIVERECORD_VERSION']
  if activerecord_version < '4.1'
    require 'minitest/unit'

    module Minitest
      Test = MiniTest::Unit::TestCase
    end
  end

  if activerecord_version < '6.2'
    require 'u-observers/for/active_record'
  end
else
  require 'u-observers'
end

require_relative 'support'

require 'minitest/pride'
require 'minitest/autorun'
