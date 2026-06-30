# frozen_string_literal: true

# Benchmark cases for the clsx-ruby optimization loop.
#
# Three tiers — each value is an arg list, splatted into clsx(*args):
#
#   REALISTIC        scored + shown per-case. Production Tailwind/Rails shapes.
#   HELDOUT          scored but hidden from the per-case table. Overfit guard:
#                    a change that helps only the visible cases shows up here.
#   CORRECTNESS_ONLY not scored. Used solely for the identical-output check
#                    (weird/infrequent inputs we must stay correct on but don't
#                    optimize for — slower here is fine).
#
# SCORED = REALISTIC + HELDOUT feeds the perf verdict. ALL feeds correctness.
module BenchmarkData
  # The two shapes that dominate real view code — called out in the verdict.
  DOMINANT = ['utility string', 'string + hash'].freeze

  REALISTIC = {
    'token'          => ['btn'],
    'utility string' => ['inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium'],
    'string + hash'  => ['btn', { primary: true, disabled: false }],
    'utility + hash' => ['inline-flex items-center gap-2', { 'opacity-50': false, 'cursor-pointer': true }],
    'string array'   => [%w[card card-bordered shadow-sm]],
    'hash'           => [{ active: true, disabled: false, loading: false }]
  }.freeze

  HELDOUT = {
    'long utility'    => ['flex flex-col sm:flex-row items-start sm:items-center gap-2 sm:gap-4 rounded-lg ' \
                          'border border-gray-200 bg-white px-3 py-2 shadow-sm hover:shadow-md transition'],
    'mixed 3-arg'     => ['card', { active: true, hidden: false }, %w[shadow rounded]],
    'string-key hash' => ['btn', { 'btn--lg' => true, 'btn--block' => false }]
  }.freeze

  CORRECTNESS_ONLY = {
    'complex' => [
      [[[['a'], 'b']]],
      { a: 1, b: 2 },
      [1, 2, 3, 4],
      { [1, 2, { %w[foo bar] => true }] => true },
      [{ fuz: 1 }, {}, {}, { baz: 'a' }, { bez: nil, bat: Float::INFINITY }],
      { { { { { z: true } => true, y: true } => true, { x: 1 } => 2 } => true } => true }
    ],
    'whitespace'      => ['  foo   bar  '],
    'tabs/newlines'   => ["foo\tbar\nbaz\tfoo"],
    'deep nested'     => [['a', ['b', ['', [['c']]]]]],
    'overlap dedup'   => ['btn btn-primary', { active: true, btn: true }],
    'complex key'     => [{ [1, 2, { %w[foo bar] => true }] => true }]
  }.freeze

  SCORED = REALISTIC.merge(HELDOUT).freeze
  ALL    = SCORED.merge(CORRECTNESS_ONLY).freeze
end
