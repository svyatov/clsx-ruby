# frozen_string_literal: true

# Full benchmark comparing optimized vs original vs Rails class_names
# Usage: bundle exec ruby benchmark/run.rb

require 'bundler/setup'
require 'benchmark/ips'
require 'clsx'

require_relative 'data'
require_relative 'original'
require_relative 'rails_class_names'

BD = BenchmarkData
Optimized = Object.new.extend(Clsx::Helper)
Original = Object.new.extend(ClsxOriginal)
Rails = Object.new.extend(RailsClassNames)

# Verify correctness before benchmarking
optimized_result = Optimized.clsx(*BD::COMPLEX).split.sort
original_result = Original.clsx(*BD::COMPLEX).split.sort

unless optimized_result == original_result
  warn 'ERROR: Optimized version produces different result!'
  warn "Original:  #{original_result.join(' ')}"
  warn "Optimized: #{optimized_result.join(' ')}"
  exit 1
end

# Scenarios Rails class_names can't handle (complex hash keys)
RAILS_SKIP = %w[complex].freeze

puts "clsx-ruby Benchmark (Ruby #{RUBY_VERSION})"
puts '=' * 60

BD::BENCHMARKS.each do |name, args|
  puts
  Benchmark.ips do |x|
    x.report("#{name} (original)") { Original.clsx(*args) }
    x.report("#{name} (optimized)") { Optimized.clsx(*args) }
    x.report("#{name} (rails)") { Rails.class_names(*args) } unless RAILS_SKIP.include?(name)
    x.compare!
  end
end
