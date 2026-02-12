# Changelog

## Unreleased

- Replaced `class ==` type checks with idiomatic `is_a?` early returns
- Extracted `clsx_single` method for clearer single-argument dispatch
- Simplified `Cn` alias from wrapper module to `Cn = Clsx`
- Removed redundant `seen.key?` guards in `clsx_process`
- Moved inline rubocop disables to `.rubocop.yml` config
- Updated benchmark baseline to compare against previous version, not ancient one

## v1.1.0

- Optimized hash-only path: skip dedup Hash since hash keys are unique by definition (+8%)
- New fast path for `clsx('base', active: cond)` string + hash pattern (+69%)
- Added `string + hash` benchmark scenario
- Use `str.dup` instead of `String.new(str)` for buffer init (+12-18% on hash paths)

## v1.0.0

- Initial release as standalone framework-agnostic gem
- Extracted from clsx-rails v2.0.0
- API: `Clsx['foo', bar: true]`, `Cn['foo', bar: true]`, `include Clsx::Helper`
- No runtime dependencies
