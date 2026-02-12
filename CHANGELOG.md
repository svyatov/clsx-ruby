# Changelog

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
