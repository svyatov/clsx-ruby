# frozen_string_literal: true

# Quick benchmark for iteration — no Rails, shorter runs
# Usage: bundle exec ruby benchmark/quick.rb

require 'bundler/setup'
require 'benchmark/ips'
require 'clsx'

require_relative 'data'
require_relative 'original'

BD = BenchmarkData
Optimized = Object.new.extend(Clsx::Helper)
Original = Object.new.extend(ClsxOriginal)

puts "clsx-ruby Quick Benchmark (Ruby #{RUBY_VERSION})"
puts '=' * 60

BD::BENCHMARKS.each do |name, args|
  Benchmark.ips do |x|
    x.warmup = 0.5
    x.time = 1
    x.report("#{name} (orig)") { Original.clsx(*args) }
    x.report("#{name} (new)") { Optimized.clsx(*args) }
    x.compare!
  end
end
