# frozen_string_literal: true

# CPU/object sampling profiler using StackProf.
# Usage: bundle exec ruby benchmark/stackprof_run.rb
#
# Generates .dump files in tmp/ for analysis:
#   stackprof tmp/stackprof-cpu.dump                      # text summary
#   stackprof tmp/stackprof-cpu.dump --method 'clsx'      # per-line detail
#   stackprof --d3-flamegraph tmp/stackprof-cpu.dump > tmp/flamegraph.html

require 'bundler/setup'
require 'stackprof'
require 'clsx'
require 'fileutils'

require_relative 'data'

BD = BenchmarkData
Optimized = Object.new.extend(Clsx::Helper)

ITERATIONS = 100_000
OUTPUT_DIR = File.expand_path('../tmp', __dir__)
FileUtils.mkdir_p(OUTPUT_DIR)

def run_all_scenarios(n)
  BD::BENCHMARKS.each_value do |args|
    n.times { Optimized.clsx(*args) }
  end
end

# CPU mode — find which methods/lines consume the most CPU time
puts 'Running CPU profile...'
StackProf.run(mode: :cpu, out: File.join(OUTPUT_DIR, 'stackprof-cpu.dump'), raw: true) do
  run_all_scenarios(ITERATIONS)
end
puts "  -> tmp/stackprof-cpu.dump"

# Object mode — find which methods/lines allocate the most objects
puts 'Running object allocation profile...'
StackProf.run(mode: :object, out: File.join(OUTPUT_DIR, 'stackprof-object.dump'), raw: true) do
  run_all_scenarios(ITERATIONS)
end
puts "  -> tmp/stackprof-object.dump"

puts 'Done. Analyze with:'
puts '  stackprof tmp/stackprof-cpu.dump'
puts '  stackprof tmp/stackprof-object.dump'
