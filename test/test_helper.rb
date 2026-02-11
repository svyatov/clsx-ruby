# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter '/test/'
  end
end

if ENV['CI']
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

require 'minitest/autorun'

require 'clsx'
