# frozen_string_literal: true

require "rubygems/package_task"
require "minitest/test_task"

gemspec = Gem::Specification.load("callback-collection.gemspec")

Minitest::TestTask.create do |task|
  task.test_globs = ["test/**/*_test.rb"]
  task.warning = true
end

Gem::PackageTask.new(gemspec).define

task default: %i[test package]
