# frozen_string_literal: true

# :nodoc:
module Clsx
  # :nodoc:
  module Helper
    # The clsx function can take any number of arguments,
    # each of which can be Hash, Array, Boolean, String, or Symbol.
    #
    # **Important**
    # Any falsy values are discarded! Standalone Boolean values are discarded as well.
    #
    # @param [Mixed] args
    #
    # @return [String] the joined class names
    #
    # @example
    #   clsx('foo', 'bar') # => 'foo bar'
    #   clsx(true, { bar: true }) # => 'bar'
    #   clsx('foo', { bar: false }) # => 'foo'
    #   clsx({ bar: true }, 'baz', { bat: false }) # => 'bar baz'
    #
    # @example within a view
    #   <div class="<%= clsx('foo', 'bar') %>">
    #   <div class="<%= clsx('foo', active: @is_active, 'another-class' => @condition) %>">
    #   <%= tag.div class: clsx(%w[foo bar], hidden: @condition) do ... end %>

    def clsx(*args)
      return nil if args.empty?
      return clsx_single(args[0]) if args.size == 1
      return clsx_string_hash(args[0], args[1]) if args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Hash)

      seen = {}
      clsx_process(args, seen)
      seen.empty? ? nil : seen.keys.join(' ')
    end

    alias cn clsx

    private

    def clsx_single(arg)
      return (arg.empty? ? nil : arg) if arg.is_a?(String)
      return arg.name if arg.is_a?(Symbol)
      return clsx_simple_hash(arg) if arg.is_a?(Hash)

      if arg.is_a?(Array) && arg.all?(String)
        seen = {}
        arg.each { |s| seen[s] = true unless s.empty? }
        return seen.empty? ? nil : seen.keys.join(' ')
      end

      seen = {}
      clsx_process([arg], seen)
      seen.empty? ? nil : seen.keys.join(' ')
    end

    # Hash-only path — no dedup hash needed (hash keys are unique by definition).
    # Builds result string directly with <<.
    def clsx_simple_hash(hash)
      return nil if hash.empty?

      buf = nil
      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          str = key.name
          buf ? (buf << ' ' << str) : (buf = str.dup)
        elsif key.is_a?(String)
          next if key.empty?

          buf ? (buf << ' ' << key) : (buf = key.dup)
        else
          seen = {}
          clsx_process([hash], seen)
          return seen.empty? ? nil : seen.keys.join(' ')
        end
      end
      buf
    end

    # String + Hash fast path: clsx('base', active: cond).
    # Builds result string directly, dedup only against base string.
    def clsx_string_hash(str, hash)
      return clsx_simple_hash(hash) if str.empty?

      buf = str.dup
      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          s = key.name
          buf << ' ' << s unless s == str
        elsif key.is_a?(String)
          buf << ' ' << key unless key.empty? || key == str
        else
          seen = { str => true }
          clsx_process([hash], seen)
          return seen.size == 1 ? str : seen.keys.join(' ')
        end
      end
      buf
    end

    def clsx_process(args, seen)
      deferred = nil

      args.each do |arg|
        if arg.is_a?(String)
          seen[arg] = true unless arg.empty?
        elsif arg.is_a?(Symbol)
          seen[arg.name] = true
        elsif arg.is_a?(Array)
          clsx_process(arg, seen)
        elsif arg.is_a?(Hash)
          arg.each { |key, value| (deferred ||= []) << key if value }
        elsif arg.is_a?(Numeric)
          seen[arg.to_s] = true
        elsif arg.nil? || arg == false || arg == true || arg.is_a?(Proc)
          next
        else
          str = arg.to_s
          seen[str] = true unless str.empty?
        end
      end

      clsx_process(deferred, seen) if deferred
    end
  end
end
