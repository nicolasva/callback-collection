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
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions construit et publie alors la gem. RubyDoc génère
automatiquement sa documentation, et les badges de version et de
téléchargements deviennent actifs après la première publication.
