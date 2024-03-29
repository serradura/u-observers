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

  <a href="https://github.com/serradura/u-observers/actions/workflows/ci.yml">
    <img alt="Build Status" src="https://github.com/serradura/u-observers/actions/workflows/ci.yml/badge.svg">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-observers/maintainability">
    <img alt="Maintainability" src="https://api.codeclimate.com/v1/badges/e72ffa84bc95c59823f2/maintainability">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-observers/test_coverage">
    <img alt="Test Coverage" src="https://api.codeclimate.com/v1/badges/e72ffa84bc95c59823f2/test_coverage">
  </a>
</p>

This gem implements the observer pattern [[1]](https://en.wikipedia.org/wiki/Observer_pattern)[[2]](https://refactoring.guru/design-patterns/observer) (also known as publish/subscribe). It provides a simple mechanism for one object to inform a set of interested third-party objects when its state changes.

Ruby's standard library [has an abstraction](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html) that enables you to use this pattern. But its design can conflict with other mainstream libraries, like the [`ActiveModel`/`ActiveRecord`](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html#method-i-changed), which also has the [`changed`](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html#method-i-changed) method. In this case, the behavior of the Stdlib will be compromised.

Because of this issue, I decided to create a gem that encapsulates the pattern without changing the object's implementation so much. The `Micro::Observers` includes just one instance method in the target class (its instance will be the observed subject/object).

> **Note:** Você entende português? 🇧🇷&nbsp;🇵🇹 Verifique o [README traduzido em pt-BR](https://github.com/serradura/u-observers/blob/main/README.pt-BR.md).

# Table of contents <!-- omit in toc -->
- [Installation](#installation)
- [Compatibility](#compatibility)
  - [Usage](#usage)
    - [Sharing a context with your observers](#sharing-a-context-with-your-observers)
    - [Sharing data when notifying the observers](#sharing-data-when-notifying-the-observers)
    - [What is a `Micro::Observers::Event`?](#what-is-a-microobserversevent)
    - [Using a callable as an observer](#using-a-callable-as-an-observer)
    - [Calling the observers](#calling-the-observers)
    - [Notifying observers without marking them as changed](#notifying-observers-without-marking-them-as-changed)
    - [Defining observers that execute only once](#defining-observers-that-execute-only-once)
      - [`observers.attach(*args, perform_once: true)`](#observersattachargs-perform_once-true)
      - [`observers.once(event:, call:, ...)`](#observersonceevent-call-)
    - [Defining observers using blocks](#defining-observers-using-blocks)
      - [`observers.on()`](#observerson)
      - [`observers.once()`](#observersonce)
      - [Replacing a block by a `lambda`/`proc`](#replacing-a-block-by-a-lambdaproc)
    - [Detaching observers](#detaching-observers)
    - [ActiveRecord and ActiveModel integrations](#activerecord-and-activemodel-integrations)
      - [`.notify_observers_on()`](#notify_observers_on)
      - [`.notify_observers()`](#notify_observers)
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
| unreleased  | main    | >= 2.2.0 | >= 3.2, < 6.1 |
| 2.3.0       | v2.x    | >= 2.2.0 | >= 3.2, < 6.1 |
| 1.0.0       | v1.x    | >= 2.2.0 | >= 3.2, < 6.1 |

> **Note**: The ActiveRecord isn't a dependency, but you could add a module to enable some static methods that were designed to be used with its [callbacks](https://guides.rubyonrails.org/active_record_callbacks.html).

[⬆️ &nbsp; Back to Top](#table-of-contents-)

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

order.observers.attach(OrderEvents)  # attaching multiple observers. e.g. observers.attach(A, B, C)
# <#Micro::Observers::Set @subject=#<Order:0x00007fb5dd8fce70> @subject_changed=false @subscribers=[OrderEvents]>

order.canceled?
# false

order.cancel!
# The message below will be printed by the observer (OrderEvents):
# The order #(X0o9yf1GsdQFvLR4) has been canceled

order.canceled?
# true

order.observers.detach(OrderEvents)  # detaching multiple observers. e.g. observers.detach(A, B, C)
# <#Micro::Observers::Set @subject=#<Order:0x00007fb5dd8fce70> @subject_changed=false @subscribers=[]>

order.canceled?
# true

order.observers.subject_changed!
order.observers.notify(:canceled) # nothing will happen, because there are no observers attached.
```

**Highlights of the previous example:**

To avoid an undesired behavior, you need to mark the subject as changed before notifying your observers about some event.

You can do this when using the `#subject_changed!` method. It will automatically mark the subject as changed.

But if you need to apply some conditional to mark a change, you can use the `#subject_changed` method. e.g. `observers.subject_changed(name != new_name)`

The `#notify` method always requires an event to make a broadcast. So, if you try to use it without one or more events (symbol values) you will get an exception.

```ruby
order.observers.notify
# ArgumentError (no events (expected at least 1))
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Sharing a context with your observers

To share a context value (any kind of Ruby object) with one or more observers, you will need to use the `:context` keyword as the last argument of the `#attach` method. This feature gives you a unique opportunity to share a value in the attaching moment.

When the observer method receives two arguments, the first one will be the subject, and the second one an instance of `Micro::Observers::Event` that will have the given context value.

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
  def self.canceled(order, event)
    puts "The order #(#{order.object_id}) has been canceled. (from: #{event.context[:from]})" # event.ctx is an alias for event.context
  end
end

order = Order.new
order.observers.attach(OrderEvents, context: { from: 'example #2' }) # attaching multiple observers. e.g. observers.attach(A, B, context: {hello: :world})
order.cancel!
# The message below will be printed by the observer (OrderEvents):
# The order #(70196221441820) has been canceled. (from: example #2)
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Sharing data when notifying the observers

As previously mentioned, the [`event context`](#sharing-a-context-with-your-observers) is a value that is stored when you attach your observer. But sometimes, it will be useful to send some additional data when broadcasting an event to the observers. The `event data` gives you this unique opportunity to share some value at the the notification moment.

```ruby
class Order
  include Micro::Observers
end

module OrderHandler
  def self.changed(order, event)
    puts "The order #(#{order.object_id}) received the number #{event.data} from #{event.ctx[:from]}."
  end
end

order = Order.new
order.observers.attach(OrderHandler, context: { from: 'example #3' })
order.observers.subject_changed!
order.observers.notify(:changed, data: 1)
# The message below will be printed by the observer (OrderHandler):
# The order #(70196221441820) received the number 1 from example #3.
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### What is a `Micro::Observers::Event`?

The `Micro::Observers::Event` is the event payload. Follow below all of its properties:

- `#name` will be the broadcasted event.
- `#subject` will be the observed object.
- `#context` will be [the context data](#sharing-a-context-with-your-observers) that was defined at the moment that you attach the observer.
- `#data` will be [the value that was shared in the observers' notification](#sharing-data-when-notifying-the-observers).
- `#ctx` is an alias for the `#context` method.
- `#subj` is an alias for the `#subject` method.

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Using a callable as an observer

The `observers.on()` method enables you to attach a callable as an observer.

Usually, a callable has a well-defined responsibility (do only one thing), because of this, it tends to be more [SRP (Single-responsibility principle)](https://en.wikipedia.org/wiki/Single-responsibility_principle) friendly than a conventional observer (that could have N methods to respond to different kinds of notification).

This method receives the below options:
1. `:event` the expected event name.
2. `:call` the callable object itself.
3. `:with` (optional) it can define the value which will be used as the callable object's argument. So, if it is a `Proc`, a `Micro::Observers::Event` instance will be received as the `Proc` argument, and its output will be the callable argument. But if this option wasn't defined, the `Micro::Observers::Event` instance will be the callable argument.
4. `:context` will be the context data that was defined in the moment that you attach the observer.

```ruby
class Person
  include Micro::Observers

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def name=(new_name)
    return unless observers.subject_changed(new_name != @name)

    @name = new_name

    observers.notify(:name_has_been_changed)
  end
end

PrintPersonName = -> (data) do
  puts("Person name: #{data.fetch(:person).name}, number: #{data.fetch(:number)}")
end

person = Person.new('Rodrigo')

person.observers.on(
  event: :name_has_been_changed,
  call: PrintPersonName,
  with: -> event { {person: event.subject, number: event.context} },
  context: rand
)

person.name = 'Serradura'
# The message below will be printed by the observer (PrintPersonName):
# Person name: Serradura, number: 0.5018509191706862
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Calling the observers

You can use a callable (a class, module, or object that responds to the call method) to be your observers.
To do this, you only need to make use of the method `#call` instead of `#notify`.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.subject_changed!
    observers.call # in practice, this is a shortcut to observers.notify(:call)
    self
  end
end

NotifyAfterCancel = -> (order) { puts "The order #(#{order.object_id}) has been canceled." }

order = Order.new
order.observers.attach(NotifyAfterCancel)
order.cancel!
# The message below will be printed by the observer (NotifyAfterCancel):
# The order #(70196221441820) has been canceled.
```

> **Note**: The `observers.call` can receive one or more events, but in this case, the default event (`call`) won't be transmitted.

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Notifying observers without marking them as changed

This feature needs to be used with caution!

If you use the methods `#notify!` or `#call!` you won't need to mark observers with `#subject_changed`.

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Defining observers that execute only once

There are two ways to attach an observer and define it to be performed only once.

The first way to do this is passing the `perform_once: true` option to the `observers.attach()` method. e.g.

#### `observers.attach(*args, perform_once: true)`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

module OrderNotifications
  def self.canceled(order)
    puts "The order #(#{order.object_id}) has been canceled."
  end
end

order = Order.new
order.observers.attach(OrderNotifications, perform_once: true) # you can also pass an array of observers with this option

order.observers.some? # true
order.cancel!         # The order #(70291642071660) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

#### `observers.once(event:, call:, ...)`

The second way to achieve this is using `observers.once()` that has the same API of [`observers.on()`](#using-a-callable-as-an-observer). But the difference of the `#once()` method is that it will remove the observer after its execution.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

module NotifyAfterCancel
  def self.call(event)
    puts "The order #(#{event.subject.object_id}) has been canceled."
  end
end

order = Order.new
order.observers.once(event: :canceled, call: NotifyAfterCancel)

order.observers.some? # true
order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Defining observers using blocks

The methods `#on()` and `#once()` can receive an event (`symbol`) and a block to define observers.

#### `observers.on()`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

order = Order.new
order.observers.on(:canceled) do |event|
  puts "The order #(#{event.subject.object_id}) has been canceled."
end

order.observers.some? # true

order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # true
```

#### `observers.once()`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

order = Order.new
order.observers.once(:canceled) do |event|
  puts "The order #(#{event.subject.object_id}) has been canceled."
end

order.observers.some? # true

order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
```

#### Replacing a block by a `lambda`/`proc`

Ruby allows you to replace any block with a `lambda`/`proc`. So, it will be possible to use this kind of feature to define your observers. e.g.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

NotifyAfterCancel = -> event { puts "The order #(#{event.subject.object_id}) has been canceled." }

order = Order.new
order.observers.once(:canceled, &NotifyAfterCancel)

order.observers.some? # true
order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### Detaching observers

As shown in the first example, you can use the `observers.detach()` to remove observers.

But, there is an alternative method to remove observer objects or remove callables by their event names. The method to do this is: `observers.off()`.

```ruby
class Order
  include Micro::Observers
end

NotifyAfterCancel = -> {}

module OrderNotifications
  def self.canceled(_order)
  end
end

order = Order.new
order.observers.on(:canceled) { |_event| }
order.observers.on(event: :canceled, call: NotifyAfterCancel)
order.observers.attach(OrderNotifications)

order.observers.some? # true
order.observers.count # 3

order.observers.off(:canceled) # removing the callable (NotifyAfterCancel).
order.observers.some? # true
order.observers.count # 1

order.observers.off(OrderNotifications)
order.observers.some? # false
order.observers.count # 0
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

### ActiveRecord and ActiveModel integrations

To make use of this feature you need to require an additional module.

Gemfile example:
```ruby
gem 'u-observers', require: 'u-observers/for/active_record'
```

This feature will expose modules that could be used to add macros (static methods) that were designed to work with `ActiveModel`/`ActiveRecord` callbacks. e.g:

#### `.notify_observers_on()`

The `notify_observers_on` allows you to define one or more `ActiveModel`/`ActiveRecord` callbacks, that will be used to notify your observers.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  notify_observers_on(:after_commit) # using multiple callbacks. e.g. notify_observers_on(:before_save, :after_commit)

  # The method above does the same as the commented example below.
  #
  # after_commit do |record|
  #  record.subject_changed!
  #  record.notify(:after_commit)
  # end
end

module TitlePrinter
  def self.after_commit(post)
    puts "Title: #{post.title}"
  end
end

module TitlePrinterWithContext
  def self.after_commit(post, event)
    puts "Title: #{post.title} (from: #{event.context[:from]})"
  end
end

Post.transaction do
  post = Post.new(title: 'Hello world')
  post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'example #6' })
  post.save
end
# The message below will be printed by the observers (TitlePrinter, TitlePrinterWithContext):
# Title: Hello world
# Title: Hello world (from: example #6)
```

[⬆️ &nbsp; Back to Top](#table-of-contents-)

#### `.notify_observers()`

The `notify_observers` allows you to define one or more *events*, that will be used to notify after the execution of some `ActiveModel`/`ActiveRecord` callback.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  after_commit(&notify_observers(:transaction_completed))

  # The method above does the same as the commented example below.
  #
  # after_commit do |record|
  #  record.subject_changed!
  #  record.notify(:transaction_completed)
  # end
end

module TitlePrinterWithContext
  def self.transaction_completed(post, event)
    puts("Title: #{post.title} (from: #{event.ctx[:from]})")
  end
end

Post.transaction do
  post = Post.new(title: 'Olá mundo')

  post.observers.on(:transaction_completed) { |event| puts("Title: #{event.subject.title}") }

  post.observers.attach(TitlePrinterWithContext, context: { from: 'example #7' })

  post.save
end
# The message below will be printed by the observers (TitlePrinter, TitlePrinterWithContext):
# Title: Olá mundo
# Title: Olá mundo (from: example #5)
```

> **Note**: You can use `include ::Micro::Observers::For::ActiveModel` if your class only makes use of the `ActiveModel` and all the previous examples will work.

[⬆️ &nbsp; Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-observers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `Micro::Observers` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).
