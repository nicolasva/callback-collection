# frozen_string_literal: true

require_relative "lib/callback/version"

Gem::Specification.new do |spec|
  spec.name = "callback"
  spec.version = Callback::VERSION
  spec.authors = ["Nicolas Vandenbogaerde"]

  spec.summary = "A small callback collection with a concise Ruby DSL"
  spec.description = "Define an immutable collection of named callbacks and invoke them with arguments."
  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_development_dependency "minitest", ">= 5", "< 7"
  spec.add_development_dependency "rake", "~> 13.0"
end
