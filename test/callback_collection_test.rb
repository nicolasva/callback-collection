# frozen_string_literal: true

require_relative "test_helper"

class CallbackCollectionTest < Minitest::Test
  module RactorHandlers
    module_function

    def sum(left, right)
      left + right
    end

    def describe(name:, active: false)
      "#{name}: #{active}"
    end

    def transform(value)
      yield(value)
    end
  end

  def setup
    @callbacks = CallbackCollection.new do |collection|
      collection.greet { |name| "Hello, #{name}!" }
      collection.sum { |left, right| left + right }
    end
  end

  def test_exposes_a_version
    refute_empty CallbackCollection::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, CallbackCollection::VERSION)
  end

  def test_uses_the_callback_collection_class_name
    assert_equal "CallbackCollection", CallbackCollection.name
  end

  def test_initializes_without_a_block
    callbacks = CallbackCollection.new

    refute_respond_to callbacks, :anything
    assert_predicate callbacks, :frozen?
    assert_predicate callbacks.send(:callbacks), :frozen?
  end

  def test_yields_the_collection_during_initialization
    yielded_collection = nil

    callbacks = CallbackCollection.new do |collection|
      yielded_collection = collection
    end

    assert_same callbacks, yielded_collection
  end

  def test_invokes_a_named_callback
    assert_equal "Hello, Ruby!", @callbacks.respond_with(:greet, "Ruby")
    assert_equal 5, @callbacks.respond_with(:sum, 2, 3)
  end

  def test_forwards_keyword_arguments
    callbacks = CallbackCollection.new do |collection|
      collection.describe { |name:, active: false| "#{name}: #{active}" }
    end

    assert_equal "Ruby: true", callbacks.respond_with(:describe, name: "Ruby", active: true)
    assert_equal "Ruby: false", callbacks.respond_with(:describe, name: "Ruby")
  end

  def test_forwards_a_block
    callbacks = CallbackCollection.new do |collection|
      collection.transform { |value, &transformer| transformer.call(value) }
    end

    result = callbacks.respond_with(:transform, "ruby", &:upcase)

    assert_equal "RUBY", result
  end

  def test_preserves_nil_and_false_return_values
    callbacks = CallbackCollection.new do |collection|
      collection.nothing { nil }
      collection.negative { false }
    end

    assert_nil callbacks.respond_with(:nothing)
    refute callbacks.respond_with(:negative)
  end

  def test_callback_keeps_its_lexical_scope
    prefix = "Hello"
    callbacks = CallbackCollection.new do |collection|
      collection.greet { |name| "#{prefix}, #{name}!" }
    end

    assert_equal "Hello, Ruby!", callbacks.respond_with(:greet, "Ruby")
  end

  def test_last_definition_wins
    callbacks = CallbackCollection.new do |collection|
      collection.status { :first }
      collection.status { :second }
    end

    assert_equal :second, callbacks.respond_with(:status)
  end

  def test_callback_definitions_can_be_chained
    callbacks = CallbackCollection.new do |collection|
      collection
        .first { 1 }
        .second { 2 }
    end

    assert_equal 1, callbacks.respond_with(:first)
    assert_equal 2, callbacks.respond_with(:second)
  end

  def test_registers_a_callback_receiver
    callbacks = CallbackCollection.new do |collection|
      collection
        .register(:sum, RactorHandlers)
        .register(:total, RactorHandlers, :sum)
    end

    assert_equal 5, callbacks.respond_with(:sum, 2, 3)
    assert_equal 9, callbacks.respond_with(:total, 4, 5)
  end

  def test_registered_callback_forwards_keywords_and_blocks
    callbacks = CallbackCollection.new do |collection|
      collection.register(:describe, RactorHandlers)
      collection.register(:transform, RactorHandlers)
    end

    assert_equal "Ruby: true", callbacks.respond_with(:describe, name: "Ruby", active: true)
    assert_equal "RUBY", callbacks.respond_with(:transform, "ruby", &:upcase)
  end

  def test_registered_callbacks_are_shareable_with_ractors
    skip "Ractor is unavailable" unless defined?(Ractor)

    callbacks = CallbackCollection.new do |collection|
      collection.register(:sum, RactorHandlers)
    end

    assert Ractor.shareable?(callbacks)

    worker = Ractor.new(callbacks) do |collection|
      collection.respond_with(:sum, 20, 22)
    end

    result = worker.respond_to?(:value) ? worker.value : worker.take

    assert_equal 42, result
  end

  def test_reports_defined_callbacks
    assert_respond_to @callbacks, :greet
    assert_respond_to @callbacks, :sum
    refute_respond_to @callbacks, :unknown
  end

  def test_callback_names_are_symbols
    error = assert_raises(NoMethodError) do
      @callbacks.respond_with("greet", "Ruby")
    end

    assert_match(/\ANo callback 'greet' is defined\./, error.message)
  end

  def test_raises_for_an_unknown_callback
    error = assert_raises(NoMethodError) do
      @callbacks.respond_with(:unknown)
    end

    assert_match(/\ANo callback 'unknown' is defined\./, error.message)
  end

  def test_unknown_method_uses_normal_method_missing_behavior
    error = assert_raises(NoMethodError) do
      @callbacks.unknown
    end

    assert_match(/undefined method [`']unknown'/, error.message)
  end

  def test_cannot_add_a_callback_after_initialization
    error = assert_raises(FrozenError) do
      @callbacks.later { :result }
    end

    assert_equal "Cannot define a callback after initialization.", error.message
    refute_respond_to @callbacks, :later
  end

  def test_cannot_register_a_callback_after_initialization
    error = assert_raises(FrozenError) do
      @callbacks.register(:later, RactorHandlers)
    end

    assert_equal "Cannot define a callback after initialization.", error.message
    refute_respond_to @callbacks, :later
  end

  def test_lambda_argument_errors_are_not_hidden
    callbacks = CallbackCollection.new do |collection|
      collection.strict_sum(&->(left, right) { left + right })
    end

    error = assert_raises(ArgumentError) do
      callbacks.respond_with(:strict_sum, 1)
    end

    assert_match(/wrong number of arguments/, error.message)
  end

  def test_callback_errors_are_not_hidden
    original_error = RuntimeError.new("callback failed")
    callbacks = CallbackCollection.new do |collection|
      collection.fail { raise original_error }
    end

    raised_error = assert_raises(RuntimeError) do
      callbacks.respond_with(:fail)
    end

    assert_same original_error, raised_error
  end

  def test_callbacks_can_be_read_concurrently
    threads = 8.times.map do
      Thread.new do
        100.times.map { @callbacks.respond_with(:sum, 20, 22) }
      end
    end

    results = threads.flat_map(&:value)

    assert_equal 800, results.length
    assert results.all? { |result| result == 42 }
  end
end
