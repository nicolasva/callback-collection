# Callback Collection

[![Build Status](https://github.com/nicolasva/callback-collection/actions/workflows/ci.yml/badge.svg)](https://github.com/nicolasva/callback-collection/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/nicolasva/callback-collection.svg)](https://codeclimate.com/github/nicolasva/callback-collection)
[![Gem Version](https://badge.fury.io/rb/callback-collection.svg)](https://badge.fury.io/rb/callback-collection)
[![Documentation Status](https://img.shields.io/badge/docs-RubyDoc.info-blue.svg)](https://www.rubydoc.info/gems/callback-collection)
[![Downloads](https://img.shields.io/gem/dt/callback-collection.svg?style=flat)](https://rubygems.org/gems/callback-collection)

A small Ruby gem for defining an immutable collection of named callbacks.

## Why Callback Collection?

`CallbackCollection` groups callback definitions during initialization and
exposes a single `respond_with` interface for invoking them. The registry
becomes immutable once constructed, preventing late additions and making its
behavior easier to test and reason about.

The gem does not replace framework callbacks or start threads or Ractors
itself. It provides an independent container that applications can use within
their own execution model.

## Architectural highlights

- **Immutable after initialization:** the collection and its internal registry
  are frozen when the configuration block completes. Callback definitions can
  then be read concurrently by multiple threads without mutating shared
  registry state.
- **Optional Ractor compatibility:** on Ruby 3.0 and later, `register` stores a
  receiver and method name instead of a closure. The collection is shareable
  when the receiver and all the state it uses are also Ractor-shareable.
- **Ruby 2.7 and later:** the standard API and `register` do not depend on
  `Ractor`. Applications running Ruby 2.7 retain the immutable registry and
  concurrent thread-read behavior.
- **Direct lookup:** `respond_with` uses `Hash#fetch` to find a callback in one
  operation and raises an explicit error when it does not exist.

Immutability protects the registry, not automatically the code executed by its
callbacks. A callback that accesses mutable shared state remains responsible
for its own synchronization.

## Installation

Install the gem from RubyGems:

```sh
gem install callback-collection
```

With Bundler, add it to your `Gemfile`:

```ruby
gem "callback-collection"
```

## Usage

```ruby
require "callback_collection"

callbacks = CallbackCollection.new do |collection|
  collection.success { |name| "Welcome, #{name}!" }
  collection.failure { |error| "Error: #{error.message}" }
end

callbacks.respond_with(:success, "Ruby")
# => "Welcome, Ruby!"
```

The collection is frozen at the end of initialization. Attempting to add a
callback afterward raises `FrozenError`.

### Ractors (Ruby 3.0 and later)

Blocks retain their lexical context and therefore cannot be shared between
Ractors. To create a shareable collection, register a shareable receiver and
one of its methods instead:

```ruby
module Handlers
  def self.sum(left, right)
    left + right
  end
end

callbacks = CallbackCollection.new do |collection|
  collection.register(:sum, Handlers)
end

Ractor.shareable?(callbacks)
# => true

worker = Ractor.new(callbacks) do |collection|
  collection.respond_with(:sum, 20, 22)
end

result = worker.respond_to?(:value) ? worker.value : worker.take
result
# => 42
```

The third argument to `register` lets you use a method name that differs from
the callback name:

```ruby
collection.register(:total, Handlers, :sum)
```

The registered receiver and the data it uses must follow Ractor shareability
rules. Calls to `respond_with` remain unchanged. On Ruby 2.7, the gem and
`register` remain fully usable; only Ractor execution is unavailable. The gem
does not create workers: the application retains control over their lifecycle
and exchanged messages.

## Development

```sh
bundle install
bundle exec rake
```

The default task runs the Minitest suite and builds the gem in `pkg/`. GitHub
Actions checks the project with Ruby 2.7 through 3.4 and the latest stable
release, Ruby 4.0.

## Publishing

RubyGems releases use
[Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) and do
not require an API key in GitHub secrets.

Before the first release, create a *Pending Trusted Publisher* in your RubyGems
profile with these settings:

- gem: `callback-collection`
- repository owner: `nicolasva`
- repository: `callback-collection`
- workflow: `release.yml`
- GitHub environment: `release`

Release a version by pushing the tag that matches
`CallbackCollection::VERSION`:

```sh
VERSION=$(ruby -Ilib -rcallback_collection/version -e 'print CallbackCollection::VERSION')
git tag "v${VERSION}"
git push origin "v${VERSION}"
```

GitHub Actions then builds and publishes the gem. RubyDoc generates its
documentation automatically, and the version and download badges update after
publication.
