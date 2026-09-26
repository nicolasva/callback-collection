# Callback Collection

[![Build Status](https://github.com/nicolasva/callback-collection/actions/workflows/ci.yml/badge.svg)](https://github.com/nicolasva/callback-collection/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/nicolasva/callback-collection.svg)](https://codeclimate.com/github/nicolasva/callback-collection)
[![Gem Version](https://badge.fury.io/rb/callback-collection.svg)](https://badge.fury.io/rb/callback-collection)
[![Documentation Status](https://img.shields.io/badge/docs-RubyDoc.info-blue.svg)](https://www.rubydoc.info/gems/callback-collection)
[![Downloads](https://img.shields.io/gem/dt/callback-collection.svg?style=flat)](https://rubygems.org/gems/callback-collection)

Une petite gem Ruby permettant de définir une collection immuable de callbacks
nommés.

## Installation

Installez la gem depuis RubyGems :

```sh
gem install callback-collection
```

Avec Bundler, ajoutez-la au `Gemfile` :

```ruby
gem "callback-collection"
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

### Ractors (Ruby 3.0 et versions ultérieures)

Les blocs conservent leur contexte lexical et ne peuvent donc pas être partagés
entre Ractors. Pour créer une collection partageable, enregistrez plutôt un
objet partageable et l'une de ses méthodes :

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

Le troisième argument de `register` permet d'utiliser un nom de méthode
différent du nom du callback :

```ruby
collection.register(:total, Handlers, :sum)
```

Le receveur enregistré et les données qu'il utilise doivent eux-mêmes respecter
les règles de partage des Ractors. L'appel à `respond_with` reste identique.
Sous Ruby 2.7, la gem et `register` restent utilisables normalement ; seule
l'exécution avec `Ractor` est indisponible.

## Développement

```sh
bundle install
bundle exec rake
```

La tâche par défaut exécute la suite Minitest et construit la gem dans `pkg/`.
L'intégration continue GitHub Actions vérifie le projet avec Ruby 2.7 à 3.4,
ainsi qu'avec la dernière version stable, Ruby 4.0.

## Publication

La publication sur RubyGems utilise
[Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) et ne
nécessite aucune clé API dans les secrets GitHub.

Avant la première publication, créez un *Pending Trusted Publisher* dans votre
profil RubyGems avec les paramètres suivants :

- gem : `callback-collection`
- propriétaire du dépôt : `nicolasva`
- dépôt : `callback-collection`
- workflow : `release.yml`
- environnement GitHub : `release`

Publiez ensuite une version en poussant le tag correspondant à
`CallbackCollection::VERSION` :

```sh
VERSION=$(ruby -Ilib -rcallback_collection/version -e 'print CallbackCollection::VERSION')
git tag "v${VERSION}"
git push origin "v${VERSION}"
```

GitHub Actions construit et publie alors la gem. RubyDoc génère
automatiquement sa documentation, et les badges de version et de
téléchargements deviennent actifs après la première publication.
