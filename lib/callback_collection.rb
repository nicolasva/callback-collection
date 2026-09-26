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
  class RegisteredCallback
    def initialize(receiver, method_name)
      @receiver = receiver
      @method_name = method_name
      freeze
    end

    def call(*args, **kwargs, &block)
      return @receiver.public_send(@method_name, *args, &block) if kwargs.empty?

      @receiver.public_send(@method_name, *args, **kwargs, &block)
    end
  end
  private_constant :RegisteredCallback

  def initialize
    callbacks
    yield(self) if block_given?
    callbacks.freeze
    freeze
  end

  def register(callback, receiver, method_name = callback)
    store_callback(callback, RegisteredCallback.new(receiver, method_name))
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
      store_callback(method_name, block)
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

  private

  def store_callback(callback, handler)
    raise FrozenError, "Cannot define a callback after initialization." if callbacks.frozen?

    callbacks[callback] = handler
    self
  end
end
