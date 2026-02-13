# frozen_string_literal: true

# Memory allocation benchmark comparing current vs experiments
# Usage: bundle exec ruby benchmark/memory.rb
# Usage: bundle exec ruby benchmark/memory.rb [experiment_number]

require 'bundler/setup'
require 'benchmark/memory'
require 'memory_profiler'
require 'clsx'

require_relative 'data'
require_relative 'original'
require_relative 'experiments'

BD = BenchmarkData
Current = Object.new.extend(Clsx::Helper)

# Filter experiments if argument provided
selected = if ARGV[0]
             num = ARGV[0]
             EXPERIMENTS.select { |k, _| k.include?("Exp#{num}") }
           else
             EXPERIMENTS
           end

exp_instances = selected.transform_values { |mod| Object.new.extend(mod) }

puts "clsx-ruby Memory Benchmark (Ruby #{RUBY_VERSION})"
puts '=' * 60

# Section 1: Allocation comparison
puts "\n--- Allocation Comparison ---\n"

BD::BENCHMARKS.each do |name, args|
  puts
  Benchmark.memory do |x|
    x.report("#{name} (current)") { Current.clsx(*args) }
    exp_instances.each do |exp_name, inst|
      x.report("#{name} (#{exp_name})") { inst.clsx(*args) }
    end
    x.compare!
  end
end

# Section 2: Detailed allocation profile
puts "\n--- Detailed Allocation Profile (current) ---\n"

BD::BENCHMARKS.each do |name, args|
  puts "\n#{name}:"
  report = MemoryProfiler.report { 100.times { Current.clsx(*args) } }
  report.pretty_print(
    detailed_report: false,
    allocated_strings: 0,
    retained_strings: 0,
    scale_bytes: true
  )
end
