# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Whitespace normalization: tabs, newlines, leading/trailing spaces, and consecutive spaces are normalized to single spaces (e.g., `clsx("foo\tbar")` returns `"foo bar"`)
- Whitespace-only strings return `nil` (e.g., `clsx("   ")` returns `nil`)

### Fixed

- Deduplicate class names across multi-token strings (e.g., `clsx("foo bar", "foo")` now returns `"foo bar"`)

## v1.1.2

### Changed

- Improved gemspec description and README marketing copy
- Switched gemspec to whitelist approach for included files

## v1.1.1

### Added

- YARD documentation to all public and private methods
- Rails 8.1.2 `class_names` as a third benchmark competitor
- ViewComponent and Phlex examples in README
- Memory and profiling benchmark scripts (`benchmark/memory.rb`, `benchmark/profile.rb`, `benchmark/stackprof_run.rb`)

### Changed

- Replaced `class ==` type checks with idiomatic `is_a?` early returns
- Extracted `clsx_single` method for clearer single-argument dispatch
- Simplified `Cn` alias from wrapper module to `Cn = Clsx`
- Removed redundant `seen.key?` guards in `clsx_process`
- Reduced allocations in `clsx_single`: pass arrays directly to `clsx_process` instead of wrapping, handle edge types inline
- Moved inline rubocop disables to `.rubocop.yml` config
- Updated benchmark baseline to compare against previous version, not ancient one
- Rewrote README with benchmark numbers and feature comparison table
- Process hash keys inline in `clsx_process` instead of deferring to a second pass (+23% mixed, +13% complex). Hash keys now appear in declaration order, matching JS clsx behavior.

## v1.1.0

### Added

- New fast path for `clsx('base', active: cond)` string + hash pattern (+69%)
- `string + hash` benchmark scenario

### Changed

- Optimized hash-only path: skip dedup Hash since hash keys are unique by definition (+8%)
- Use `str.dup` instead of `String.new(str)` for buffer init (+12-18% on hash paths)

## v1.0.0

### Added

- Initial release as standalone framework-agnostic gem
- Extracted from clsx-rails v2.0.0
- API: `Clsx['foo', bar: true]`, `Cn['foo', bar: true]`, `include Clsx::Helper`
- No runtime dependencies
