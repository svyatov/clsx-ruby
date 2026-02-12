# frozen_string_literal: true

require_relative 'clsx/version'
require_relative 'clsx/helper'

# Construct CSS class strings conditionally.
# Ruby port of the JavaScript {https://github.com/lukeed/clsx clsx} package.
#
# @example
#   Clsx['foo', 'bar']                  # => "foo bar"
#   Clsx['btn', active: true]           # => "btn active"
#   Cn['hidden', visible: false]        # => "hidden"
module Clsx
  extend Helper

  # (see Helper#clsx)
  def self.[](*)
    clsx(*)
  end
end

# Short alias — only defined if +Cn+ is not already taken.
Cn = Clsx unless Object.const_defined?(:Cn)
