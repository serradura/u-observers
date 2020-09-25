require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch if RUBY_VERSION >= '2.5.0'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'micro/observers'

require_relative 'support'

require 'minitest/pride'
require 'minitest/autorun'
