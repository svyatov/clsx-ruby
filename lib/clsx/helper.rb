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
      return clsx_one(args[0]) if args.size == 1

      if args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Hash)
        str = args[0]
        return clsx_hash(args[1]) if str.empty?
        return clsx_str_hash_full(str, args[1]) if str.include?(' ') || str.include?("\t") || str.include?("\n") # rubocop:disable Layout/EmptyLineAfterGuardClause
        return clsx_str_hash(str, args[1])
      end

      seen = {}
      clsx_walk(args, seen)
      clsx_join(seen)
    end

    # (see #clsx)
    alias cn clsx

    private

    # Single-argument fast path — dispatches by type, handles multi-token
    # string dedup without allocating a walker Hash for simple cases.
    #
    # @param arg [Object] single class descriptor
    # @return [String, nil]
    def clsx_one(arg)
      if arg.is_a?(String)
        return nil if arg.empty?
        return arg unless arg.include?(' ') || arg.include?("\t") || arg.include?("\n")

        parts = arg.split
        return nil if parts.empty?
        return parts[0] if parts.length == 1
        return arg if !parts.uniq! && parts.length == arg.count(' ') + 1 # rubocop:disable Layout/EmptyLineAfterGuardClause
        return parts.join(' ')
      end

      if arg.is_a?(Symbol)
        s = arg.name
        return s unless s.include?(' ') || s.include?("\t") || s.include?("\n") # rubocop:disable Layout/EmptyLineAfterGuardClause
        return clsx_dedup_str(s)
      end

      return clsx_hash(arg) if arg.is_a?(Hash)

      if arg.is_a?(Array)
        return nil if arg.empty?

        seen = {}
        clsx_walk(arg, seen)
        return clsx_join(seen)
      end

      return nil if !arg || arg == true || arg.is_a?(Proc)

      s = arg.to_s
      s.empty? ? nil : s
    end

    # Dedup and normalize a multi-token string. Handles whitespace-only
    # input, leading/trailing whitespace, tabs, newlines, and duplicates.
    #
    # @param str [String] space-separated class string
    # @return [String, nil]
    def clsx_dedup_str(str)
      parts = str.split
      return nil if parts.empty?
      return parts[0] if parts.length == 1
      return str if !parts.uniq! && parts.length == str.count(' ') + 1

      parts.join(' ')
    end

    # Hash-only fast path using string buffer. Falls back to Hash dedup
    # on mixed key types, multi-token keys, or complex keys.
    #
    # @param hash [Hash] class-name => condition pairs
    # @return [String, nil]
    def clsx_hash(hash)
      return nil if hash.empty?

      buf = nil
      key_type = nil

      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          return clsx_hash_full(hash) if key_type == :string

          key_type = :symbol
          s = key.name
          return clsx_hash_full(hash) if s.include?(' ')

          buf ? (buf << ' ' << s) : (buf = s.dup)
        elsif key.is_a?(String)
          next if key.empty?

          return clsx_hash_full(hash) if key_type == :symbol
          return clsx_hash_full(hash) if key.include?(' ')

          key_type = :string
          buf ? (buf << ' ' << key) : (buf = key.dup)
        else
          return clsx_hash_full(hash)
        end
      end

      return nil unless buf
      return clsx_dedup_str(buf) if buf.include?("\t") || buf.include?("\n")

      buf
    end

    # Hash fallback with full dedup via walker.
    #
    # @param hash [Hash] class-name => condition pairs
    # @return [String, nil]
    def clsx_hash_full(hash)
      seen = {}
      clsx_walk_hash(hash, seen)
      clsx_join(seen)
    end

    # Fast path for +clsx('base', active: cond)+ pattern where base is a
    # single token. Deduplicates via direct string comparison.
    #
    # @param str [String] base class name
    # @param hash [Hash] class-name => condition pairs
    # @return [String, nil]
    def clsx_str_hash(str, hash)
      buf = str.dup
      key_type = nil

      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          return clsx_str_hash_full(str, hash) if key_type == :string

          key_type = :symbol
          s = key.name
          return clsx_str_hash_full(str, hash) if s.include?(' ')

          next if s == str

          buf << ' ' << s
        elsif key.is_a?(String)
          return clsx_str_hash_full(str, hash) if key_type == :symbol

          key_type = :string
          next if key.empty?

          return clsx_str_hash_full(str, hash) if key.include?(' ')

          next if key == str

          buf << ' ' << key
        else
          return clsx_str_hash_full(str, hash)
        end
      end

      return clsx_dedup_str(buf) if buf.include?("\t") || buf.include?("\n")

      buf
    end

    # Full str+hash dedup using array lookup. Splits the base string once,
    # then checks hash keys against the parts array via linear search.
    # Falls back to Hash dedup on mixed key types or complex keys.
    #
    # @param str [String] base class name (contains spaces)
    # @param hash [Hash] class-name => condition pairs
    # @return [String, nil]
    def clsx_str_hash_full(str, hash)
      parts = str.split
      return clsx_hash(hash) if parts.empty?
      return clsx_str_hash_full_walk(parts, hash) if parts.length == 1

      buf = if parts.uniq! || parts.length != str.count(' ') + 1
              parts.join(' ')
            else
              str.dup
            end

      key_type = nil

      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          return clsx_str_hash_full_walk(parts, hash) if key_type == :string

          key_type = :symbol
          s = key.name
          return clsx_str_hash_full_walk(parts, hash) if s.include?(' ') || s.include?("\t") || s.include?("\n")

          next if parts.include?(s)

          buf << ' ' << s
        elsif key.is_a?(String)
          return clsx_str_hash_full_walk(parts, hash) if key_type == :symbol

          key_type = :string
          next if key.empty?
          return clsx_str_hash_full_walk(parts, hash) if key.include?(' ') || key.include?("\t") || key.include?("\n")

          next if parts.include?(key)

          buf << ' ' << key
        else
          return clsx_str_hash_full_walk(parts, hash)
        end
      end

      buf
    end

    # Hash-based fallback for str+hash when array lookup can't handle it.
    #
    # @param parts [Array<String>] pre-split base tokens
    # @param hash [Hash] class-name => condition pairs
    # @return [String, nil]
    def clsx_str_hash_full_walk(parts, hash)
      seen = {}
      parts.each { |s| seen[s] = true }
      clsx_walk_hash(hash, seen)
      clsx_join(seen)
    end

    # General-purpose recursive walker. Stores strings as-is; normalization
    # and dedup are handled by {#clsx_join} after walking.
    #
    # @param args [Array] nested arguments to walk
    # @param seen [Hash{String => true}] accumulator for deduplication
    # @return [void]
    def clsx_walk(args, seen)
      args.each do |arg|
        if arg.is_a?(String)
          seen[arg] = true unless arg.empty?
        elsif arg.is_a?(Symbol)
          seen[arg.name] = true
        elsif arg.is_a?(Array)
          clsx_walk(arg, seen)
        elsif arg.is_a?(Hash)
          clsx_walk_hash(arg, seen)
        elsif !arg || arg == true || arg.is_a?(Proc)
          next
        else
          s = arg.to_s
          seen[s] = true unless s.empty?
        end
      end
    end

    # Hash-specific walker — avoids wrapping hash in an array for recursion.
    #
    # @param hash [Hash] hash to walk
    # @param seen [Hash{String => true}] accumulator
    # @return [void]
    def clsx_walk_hash(hash, seen)
      return if hash.empty?

      hash.each do |key, value|
        next unless value

        if key.is_a?(Symbol)
          seen[key.name] = true
        elsif key.is_a?(String)
          seen[key] = true unless key.empty?
        elsif key.is_a?(Array)
          clsx_walk(key, seen)
        elsif key.is_a?(Hash)
          clsx_walk_hash(key, seen)
        elsif !key || key == true || key.is_a?(Proc)
          next
        else
          s = key.to_s
          seen[s] = true unless s.empty?
        end
      end
    end

    # Post-join dedup and normalization: detects multi-token entries via
    # space count mismatch or tab/newline presence, then splits and rebuilds.
    #
    # @param seen [Hash{String => true}] token accumulator
    # @return [String, nil] space-joined class string
    def clsx_join(seen)
      return nil if seen.empty?

      result = seen.keys.join(' ')
      return result if result.count(' ') + 1 == seen.size && !result.include?("\t") && !result.include?("\n")

      normalized = result.split.uniq.join(' ')
      normalized.empty? ? nil : normalized
    end
  end
end
