# frozen_string_literal: true

require_relative "callback_collection/version"

# Stores named callbacks during initialization, then exposes thread-safe reads.
#
# @example
#   callbacks = CallbackCollection.new do |collection|
#     collection.success { |value| "Received #{value}" }
#   end
#
#   callbacks.respond_with(:success, "data")
#   # => "Received data"
class CallbackCollection
  def initialize
    callbacks
    yield(self) if block_given?
    callbacks.freeze
  end

  def respond_with(callback, *args, **kwargs, &block)
    handler = callbacks.fetch(callback) do
      raise NoMethodError, "No callback '#{callback}' is defined."
    end

    return handler.call(*args, &block) if kwargs.empty?

    handler.call(*args, **kwargs, &block)
  end

  def method_missing(method_name, *args, &block)
    if block
      raise FrozenError, "Cannot define a callback after initialization." if callbacks.frozen?

      callbacks[method_name] = block
      self
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    callbacks.key?(method_name) || super
  end

  protected

  def callbacks
    @callbacks ||= {}
  end
end
