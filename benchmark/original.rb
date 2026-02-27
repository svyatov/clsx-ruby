# frozen_string_literal: true

# v1.1.2 release implementation (no multi-token dedup)
module ClsxOriginal
  def clsx(*args)
    return nil if args.empty?
    return clsx_single(args[0]) if args.size == 1
    return clsx_string_hash(args[0], args[1]) if args.size == 2 && args[0].is_a?(String) && args[1].is_a?(Hash)

    seen = {}
    clsx_process(args, seen)
    seen.empty? ? nil : seen.keys.join(' ')
  end

  private

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
    args.each do |arg|
      if arg.is_a?(String)
        seen[arg] = true unless arg.empty?
      elsif arg.is_a?(Symbol)
        seen[arg.name] = true
      elsif arg.is_a?(Array)
        clsx_process(arg, seen)
      elsif arg.is_a?(Hash)
        arg.each do |key, value|
          next unless value

          if key.is_a?(Symbol)
            seen[key.name] = true
          elsif key.is_a?(String)
            seen[key] = true unless key.empty?
          else
            clsx_process([key], seen)
          end
        end
      elsif arg.is_a?(Numeric)
        seen[arg.to_s] = true
      elsif !arg || arg == true || arg.is_a?(Proc)
        next
      else
        str = arg.to_s
        seen[str] = true unless str.empty?
      end
    end
  end
end
