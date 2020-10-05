<p align="center">
  <h1 align="center">👀 μ-observers</h1>
  <p align="center"><i>Simple and powerful implementation of the observer pattern.</i></p>
  <br>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ruby->%3D%202.2.0-ruby.svg?colorA=99004d&colorB=cc0066" alt="Ruby">

  <a href="https://rubygems.org/gems/u-observers">
    <img alt="Gem" src="https://img.shields.io/gem/v/u-observers.svg?style=flat-square">
  </a>

  <a href="https://travis-ci.com/serradura/u-observers">
    <img alt="Build Status" src="https://travis-ci.com/serradura/u-observers.svg?branch=main">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-observers/maintainability">
    <img alt="Maintainability" src="https://api.codeclimate.com/v1/badges/e72ffa84bc95c59823f2/maintainability">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-observers/test_coverage">
    <img alt="Test Coverage" src="https://api.codeclimate.com/v1/badges/e72ffa84bc95c59823f2/test_coverage">
  </a>
</p>

This gem implements the observer pattern [[1]](https://en.wikipedia.org/wiki/Observer_pattern)[[2]](https://refactoring.guru/design-patterns/observer) (also known as publish/subscribe). It provides a simple mechanism for one object to inform a set of interested third-party objects when its state changes.

Ruby's standard library [has an abstraction](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html) that enables you to use this pattern. But its design can conflict with other mainstream libraries, like the [`ActiveModel`/`ActiveRecord`](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html#method-i-changed), which also has the [`changed`](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html#method-i-changed) method. In this case, the behavior of the Stdlib will be been compromised.

Because of this issue, I decided to create a gem that encapsulates the pattern without changing the object's implementation so much. The `Micro::Observers` includes just one instance method in the target class (its instance will be the observed subject).

# Table of contents <!-- omit in toc -->
- [Installation](#installation)
- [Compatibility](#compatibility)
  - [Usage](#usage)
    - [Passing a context for your observers](#passing-a-context-for-your-observers)
    - [Calling the observers](#calling-the-observers)
    - [Notifying observers without marking them as changed](#notifying-observers-without-marking-them-as-changed)
    - [ActiveRecord and ActiveModel integrations](#activerecord-and-activemodel-integrations)
      - [notify_observers_on()](#notify_observers_on)
      - [notify_observers()](#notify_observers)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

# Installation

Add this line to your application's Gemfile and `bundle install`:

```ruby
gem 'u-observers'
```

# Compatibility

| u-observers | branch  | ruby     | activerecord  |
| ----------- | ------- | -------- | ------------- |
| 1.0.0       | main    | >= 2.2.0 | >= 3.2, < 6.1 |

> **Note**: The ActiveRecord isn't a dependency, but you could add a module to enable some static methods that were designed to be used with its [callbacks](https://guides.rubyonrails.org/active_record_callbacks.html).

[⬆️ Back to Top](#table-of-contents-)

## Usage

Any class with `Micro::Observers` module included can notify events to attached observers.

```ruby
require 'securerandom'

class Order
  include Micro::Observers

  attr_reader :code

  def initialize
    @code, @status = SecureRandom.alphanumeric, :draft
  end

  def canceled?
    @status == :canceled
  end

  def cancel!
    return self if canceled?

    @status = :canceled

    observers.subject_changed!
    observers.notify(:canceled) and return self
  end
end

module OrderEvents
  def self.canceled(order)
    puts "The order #(#{order.code}) has been canceled."
  end
end

order = Order.new
#<Order:0x00007fb5dd8fce70 @code="X0o9yf1GsdQFvLR4", @status=:draft>

order.observers.attach(OrderEvents) # attaching multiple observers. e.g. observers.attach(A, B, C)
# <#Micro::Observers::Manager @subject=#<Order:0x00007fb5dd8fce70> @subject_changed=false @subscribers=[OrderEvents]

order.canceled?
# false

order.cancel!
# The message below will be printed by the observer (OrderEvents):
# The order #(X0o9yf1GsdQFvLR4) has been canceled

order.canceled?
# true
```

**Highlights of the previous example:**

To avoid an undesired behavior, do you need to mark the subject as changed before notify your observers about some event.

You can do this when using the `#subject_changed!` method. It will automatically mark the subject as changed.

But if you need to apply some conditional to mark a change, you can use the `#subject_changed` method. e.g. `observers.subject_changed(name != new_name)`

The `#notify` method always requires an event to make a broadcast. So, if you try to use it without one or more events (symbol values) you will get an exception.

```ruby
order.observers.notify
# ArgumentError (no events (expected at least 1))
```

[⬆️ Back to Top](#table-of-contents-)

### Passing a context for your observers

To pass a context (any kind of Ruby object) for one or more observers, you will need to use the `context:` keyword as the last argument of the `#attach` method.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.subject_changed!
    observers.notify(:canceled)
    self
  end
end

module OrderEvents
  def self.canceled(order, context)
    puts "The order #(#{order.code}) has been canceled. (from: #{context[:from]})"
  end
end

order = Order.new
order.observers.attach(OrderEvents, context: { from: 'example #2' ) # attaching multiple observers. e.g. observers.attach(A, B, context: {hello: :world})
order.cancel!
# The message below will be printed by the observer (OrderEvents):
# The order #(70196221441820) has been canceled. (from: example #2)
```

[⬆️ Back to Top](#table-of-contents-)

### Calling the observers

You can use a callable (a class, module, or object that responds to the call method) to be your observers.
To do this, you only need make use of the method `#call` instead of `#notify`.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.subject_changed!
    observers.call # in practice, this is a shortcut to observers.notify(:call)
    self
  end
end

OrderCancellation = -> (order) { puts "The order #(#{order.object_id}) has been canceled." }

order = Order.new
order.observers.attach(OrderCancellation)
order.cancel!
# The message below will be printed by the observer (OrderEvents):
# The order #(70196221441820) has been canceled.
```

PS: The `observers.call` can receive one or more events, but in this case, the default event (`call`) won't be transmitted.a

[⬆️ Back to Top](#table-of-contents-)

### Notifying observers without marking them as changed

This feature needs to be used with caution!

If you use the methods `#notify!` or `#call!` you won't need to mark observers with `#subject_changed`.

[⬆️ Back to Top](#table-of-contents-)

### ActiveRecord and ActiveModel integrations

To make use of this feature you need to require an additional module (`require 'u-observers/for/active_record'`).

Gemfile example:
```ruby
gem 'u-observers', require: 'u-observers/for/active_record'
```

This feature will expose modules that could be used to add macros (static methods) that were designed to work with `ActiveModel`/`ActiveRecord` callbacks. e.g:


#### notify_observers_on()

The `notify_observers_on` allows you to pass one or more `ActiveModel`/`ActiveRecord` callbacks, that will be used to notify your object observers.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  notify_observers_on(:after_commit) # passing multiple callbacks. e.g. notify_observers_on(:before_save, :after_commit)
end

module TitlePrinter
  def self.after_commit(post)
    puts "Title: #{post.title}"
  end
end

module TitlePrinterWithContext
  def self.after_commit(post, context)
    puts "Title: #{post.title} (from: #{context[:from]})"
  end
end

Post.transaction do
  post = Post.new(title: 'Hello world')
  post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'example 4' })
  post.save
end
# The message below will be printed by the observer (OrderEvents):
# Title: Hello world
# Title: Hello world (from: example 4)
```

[⬆️ Back to Top](#table-of-contents-)

#### notify_observers()

The `notify_observers` allows you to pass one or more *events*, that will be used to notify after the execution of some `ActiveModel`/`ActiveRecord` callback.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  after_commit(&notify_observers(:transaction_completed))
end

module TitlePrinter
  def self.transaction_completed(post)
    puts("Title: #{post.title}")
  end
end

module TitlePrinterWithContext
  def self.transaction_completed(post, context)
    puts("Title: #{post.title} (from: #{context[:from]})")
  end
end

Post.transaction do
  post = Post.new(title: 'Olá mundo')
  post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'example 5' })
  post.save
end
# The message below will be printed by the observer (OrderEvents):
# Title: Olá mundo
# Title: Olá mundo (from: example 5)
```

PS: You can use `include ::Micro::Observers::For::ActiveModel` if your class only makes use of the `ActiveModel` and all the previous examples will work.

[⬆️ Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-observers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `Micro::Observers` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).
