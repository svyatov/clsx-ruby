# frozen_string_literal: true

# Deep-dive per-line allocation profiler for a single scenario.
# Usage: bundle exec ruby benchmark/profile.rb [scenario_name]
#
# Examples:
#   bundle exec ruby benchmark/profile.rb "single string"
#   bundle exec ruby benchmark/profile.rb hash
#   bundle exec ruby benchmark/profile.rb          # defaults to "string + hash"

require 'bundler/setup'
require 'memory_profiler'
require 'clsx'

require_relative 'data'

BD = BenchmarkData
Optimized = Object.new.extend(Clsx::Helper)

scenario = ARGV[0] || 'string + hash'
args = BD::BENCHMARKS[scenario]

unless args
  warn "Unknown scenario: #{scenario.inspect}"
  warn "Available: #{BD::BENCHMARKS.keys.join(', ')}"
  exit 1
end

puts "Profiling scenario: #{scenario}"
puts "Args: #{args.inspect}"
puts '=' * 60

report = MemoryProfiler.report { 1000.times { Optimized.clsx(*args) } }
report.pretty_print
