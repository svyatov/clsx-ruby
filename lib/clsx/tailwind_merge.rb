# frozen_string_literal: true

require 'clsx'
require 'tailwind_merge'

# Opt-in Tailwind merging. Requiring this file (once, at boot) pulls in the
# {https://github.com/gjtorikian/tailwind_merge tailwind_merge} gem and adds a
# merged variant of +clsx+ — {Clsx.twm}, the {Helper#twm} mixin method, and the
# +Twm[]+ shortcut — that resolves conflicting Tailwind utilities
# (e.g. +"px-2 px-4"+ becomes +"px-4"+).
#
# +clsx+/+cn+ are left untouched and stay pure; only +twm+/+Twm+ merge. Without
# requiring this file the core gem carries no dependency.
#
# @example
#   require 'clsx/tailwind_merge'
#   Twm['px-2 px-4']  # => "px-4"
#
# @example Custom merger (configure once at boot)
#   Clsx.merger = TailwindMerge::Merger.new(config: { prefix: 'tw' })
module Clsx
  @merger_mutex = Mutex.new

  class << self
    # @param merger [#merge] a preconfigured merger (or +nil+ to reset to the lazy default)
    # @return [#merge, nil]
    attr_writer :merger

    # Process-wide merger, built once. Building a {TailwindMerge::Merger} is
    # expensive, so double-checked locking constructs it exactly once even under
    # concurrent first use; after that the lock is never taken again.
    #
    # @return [#merge]
    def merger
      @merger || @merger_mutex.synchronize { @merger ||= TailwindMerge::Merger.new }
    end
  end

  # Adds the merged {#twm} variant to the {Helper} mixin.
  module Helper
    # Like {#clsx}, but pipes the result through {Clsx.merger} to resolve
    # conflicting Tailwind utilities. Returns +nil+ (skipping the merger) when no
    # classes apply, matching {#clsx}.
    #
    # @return [String, nil]
    #
    # @example
    #   twm('px-2 px-4')                 # => "px-4"
    #   twm('px-2', 'px-4', hidden: c)   # => "px-4"
    def twm(*)
      classes = clsx(*)
      classes && Clsx.merger.merge(classes)
    end
  end

  # Bracket shortcut for {Helper#twm}, mirroring {Clsx.[]}.
  module Twm
    # (see Helper#twm)
    def self.[](*)
      Clsx.twm(*)
    end
  end
end

# Short top-level shortcut — only defined if +Twm+ is not already taken.
Twm = Clsx::Twm unless Object.const_defined?(:Twm)
