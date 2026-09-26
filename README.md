# Callback Collection

[![Build Status](https://github.com/nicolasva/callback/actions/workflows/ci.yml/badge.svg)](https://github.com/nicolasva/callback/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/nicolasva/callback.svg)](https://codeclimate.com/github/nicolasva/callback)
[![Gem Version](https://badge.fury.io/rb/callback-collection.svg)](https://badge.fury.io/rb/callback-collection)
[![Documentation Status](https://inch-ci.org/github/nicolasva/callback.svg?branch=main)](https://inch-ci.org/github/nicolasva/callback)
[![Downloads](https://img.shields.io/gem/dt/callback-collection.svg?style=flat)](https://rubygems.org/gems/callback-collection)

Une petite gem Ruby permettant de définir une collection immuable de callbacks
nommés.

## Installation

Construisez puis installez la gem localement :

```sh
gem build callback-collection.gemspec
gem install callback-collection-0.1.0.gem
```

Dans un projet Bundler local, vous pouvez aussi ajouter :

```ruby
gem "callback-collection", path: "/path/to/callback-collection"
```

## Utilisation

```ruby
require "callback_collection"

callbacks = CallbackCollection.new do |collection|
  collection.success { |name| "Bienvenue, #{name} !" }
  collection.failure { |error| "Erreur : #{error.message}" }
end

callbacks.respond_with(:success, "Ruby")
# => "Bienvenue, Ruby !"
```

La collection est figée à la fin de son initialisation. Toute tentative
d'ajouter ensuite un callback lève une `FrozenError`.

## Développement

```sh
bundle install
bundle exec rake
```

La tâche par défaut exécute la suite Minitest et construit la gem dans `pkg/`.
L'intégration continue GitHub Actions vérifie le projet avec Ruby 2.7 à 3.4,
ainsi qu'avec la dernière version stable, Ruby 4.0.
