# Callback

Une petite gem Ruby permettant de définir une collection immuable de callbacks
nommés.

## Installation

Construisez puis installez la gem localement :

```sh
gem build callback.gemspec
gem install callback-0.1.0.gem
```

Dans un projet Bundler local, vous pouvez aussi ajouter :

```ruby
gem "callback", path: "/Users/nicolasvandenbogaerde/VANDENBOGAERDE_Nicolas/ruby/callback"
```

## Utilisation

```ruby
require "callback"

callbacks = Callback::CallbackCollection.new do |collection|
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
