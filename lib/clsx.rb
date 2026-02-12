# frozen_string_literal: true

require_relative 'clsx/version'
require_relative 'clsx/helper'

# :nodoc:
module Clsx
  extend Helper

  def self.[](*)
    clsx(*)
  end
end

# Short alias — only defined if `Cn` is not already taken
Cn = Clsx unless Object.const_defined?(:Cn)
