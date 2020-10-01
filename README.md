<p align="center">
  <h1 align="center">📻 μ-observers</h1>
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

Because of this issue, I decided to create a gem that encapsulates the pattern without changing the object's implementation so much. The `Micro::Observers` includes one instance method and two static methods.

# Table of contents <!-- omit in toc -->
- [Installation](#installation)
- [Compatibility](#compatibility)
  - [Usage](#usage)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

# Installation

Add this line to your application's Gemfile and `bundle install`:

```ruby
gem 'u-attributes'
```

# Compatibility

| u-attributes   | branch  | ruby     |  activerecord |
| -------------- | ------- | -------- | ------------- |
| 0.9.0          | main    | >= 2.2.0 | >= 3.2, < 6.1 |

> **Note**: The ActiveRecord isn't a dependency, but the static methods that are included by the gem were designed to be used with its [callbacks](https://guides.rubyonrails.org/active_record_callbacks.html).

[⬆️ Back to Top](#table-of-contents-)

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serradura/u-observers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `Micro::Observers` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/serradura/u-observers/blob/master/CODE_OF_CONDUCT.md).
