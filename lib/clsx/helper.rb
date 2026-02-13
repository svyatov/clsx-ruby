# frozen_string_literal: true

module Clsx
  # Mixin providing {#clsx} and {#cn} instance methods.
  #
  # @example
  #   include Clsx::Helper
  #   clsx('btn', active: @active)  # => "btn active"
  module Helper
    # Build a CSS class string from an arbitrary mix of arguments.
    #
    # Falsy values (+nil+, +false+) and standalone +true+ are discarded.
    # Duplicates are eliminated. Returns +nil+ (not +""+) when no classes apply.
    #
    # @param args [String, Symbol, Hash, Array, Numeric, nil, false] class descriptors
    #   to merge into a single space-separated string
    # @return [String] space-joined class string
    # @return [nil] when no classes apply
    #
    # @example Strings and hashes
    #   clsx('foo', 'bar')                      # => "foo bar"
    #   clsx(foo: true, bar: false, baz: true)  # => "foo baz"
    #
    # @example Nested arrays
    #   clsx('a', ['b', nil, ['c']])            # => "a b c"
    #   clsx(%w[foo bar], hidden: true)         # => "foo bar hidden"
    def clsx(*args)
      return nil if args.empty?
      return clsx_single(args[0]) if args.size == 1
      return clsx_string_hash(args[0], args[1]) if args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Hash)

      seen = {}
      clsx_process(args, seen)
      seen.empty? ? nil : seen.keys.join(' ')
    end

    # (see #clsx)
    alias cn clsx

    private

    # Single-argument fast path — dispatches by type to avoid allocating
    # a +seen+ hash when possible.
    #
    # @param arg [String, Symbol, Hash, Array] single class descriptor
    # @return [String] resolved class string
    # @return [nil] when the argument produces no classes
    def clsx_single(arg)
      return (arg.empty? ? nil : arg) if arg.is_a?(String)
      return arg.name if arg.is_a?(Symbol)
      return clsx_simple_hash(arg) if arg.is_a?(Hash)

      if arg.is_a?(Array)
        return nil if arg.empty?

        if arg.all?(String)
          seen = {}
          arg.each { |s| seen[s] = true unless s.empty? }
          return seen.empty? ? nil : seen.keys.join(' ')
        end

        seen = {}
        clsx_process(arg, seen)
        return seen.empty? ? nil : seen.keys.join(' ')
      end

      return arg.to_s if arg.is_a?(Numeric)
      return nil if !arg || arg == true || arg.is_a?(Proc)

      str = arg.to_s
      str.empty? ? nil : str
    end

    # Hash-only fast path — no dedup needed since hash keys are unique.
    # Falls back to {#clsx_process} on non-String/Symbol keys.
    #
    # @param hash [Hash{String, Symbol => Boolean}] class-name => condition pairs
    # @return [String] resolved class string
    # @return [nil] when no hash values are truthy
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

    # Fast path for +clsx('base', active: cond)+ — deduplicates only against
    # the base string. Falls back to {#clsx_process} on non-String/Symbol keys.
    #
    # @param str [String] base class name
    # @param hash [Hash{String, Symbol => Boolean}] class-name => condition pairs
    # @return [String] resolved class string
    # @return [nil] when no classes apply
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

    # General-purpose recursive walker. Hash values are deferred and processed
    # after flat args so that hash keys resolve in a second pass.
    #
    # @param args [Array<String, Symbol, Hash, Array, Numeric, nil, false>] nested arguments
    # @param seen [Hash{String => true}] accumulator for deduplication
    # @return [void]
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
        elsif !arg || arg == true || arg.is_a?(Proc)
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
