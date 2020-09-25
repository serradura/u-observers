require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection(
  host: 'localhost',
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.column :title, :string
  end

  create_table :books do |t|
    t.column :title, :string
  end
end

require 'singleton'

class FakePrinter
  include Singleton

  def self.history; instance.history; end
  def self.puts(value); instance.puts(value); end

  attr_reader :history

  def initialize
    @history = []
  end

  def puts(value)
    @history << value
  end
end
