# frozen_string_literal: true

# clsx-ruby vs Rails `class_names` — the public, runnable benchmark behind the
# README perf table:
#
#   bundle exec ruby benchmark/vs_rails.rb
#
# Cases come from data.rb; the Rails replication lives in rails_class_names.rb.
# Only cases where clsx and Rails produce *identical* output are timed (others
# are skipped with a warning), so the comparison is apples-to-apples.

require 'bundler/setup'
require 'benchmark/ips'
require 'clsx'

require_relative 'data'
require_relative 'rails_class_names'

BD = BenchmarkData

# The production-like cases, plus one long utility string to show clsx stays
# ahead as token count grows.
CASES = BD::REALISTIC.merge('long utility' => BD::HELDOUT['long utility']).freeze

clsx  = Object.new.extend(Clsx::Helper)
rails = Object.new.extend(RailsClassNames)

def silence
  orig = $stdout
  $stdout = File.open(File::NULL, 'w')
  yield
ensure
  $stdout.close
  $stdout = orig
end

def humanize(ips)
  return format('%.0f i/s', ips) if ips < 1_000
  return format('%.0fK i/s', ips / 1_000) if ips < 1_000_000

  format('%.1fM i/s', ips / 1_000_000)
end

def geomean(values) = Math.exp(values.sum { |v| Math.log(v) } / values.size)

rows = CASES.filter_map do |name, args|
  c = clsx.clsx(*args)
  r = rails.class_names(*args)
  unless c == r
    warn "SKIP #{name.inspect}: outputs differ (clsx=#{c.inspect} rails=#{r.inspect})"
    next
  end

  report = nil
  silence do
    report = Benchmark.ips do |x|
      x.warmup = 1
      x.time   = 3
      x.report('clsx')  { clsx.clsx(*args) }
      x.report('rails') { rails.class_names(*args) }
    end
  end
  ci = report.entries.find { |e| e.label == 'clsx' }.stats.central_tendency
  ri = report.entries.find { |e| e.label == 'rails' }.stats.central_tendency
  { label: name.capitalize, clsx: ci, rails: ri, speedup: ci / ri }
end.sort_by { |row| -row[:speedup] }

geo = geomean(rows.map { |row| row[:speedup] })

puts "clsx vs Rails class_names (Ruby #{RUBY_VERSION})"
puts "geomean speedup: #{format('%.1fx', geo)}  " \
     "(range #{format('%.1fx', rows.last[:speedup])}–#{format('%.1fx', rows.first[:speedup])})"
puts
puts '| Scenario | clsx-ruby | Rails `class_names` | Speedup |'
puts '|---|---|---|---|'
rows.each do |row|
  puts format('| %s | %s | %s | **%.1fx** |',
              row[:label], humanize(row[:clsx]), humanize(row[:rails]), row[:speedup])
end
