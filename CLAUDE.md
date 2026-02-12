# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

clsx-ruby is a Ruby gem that provides a utility (`clsx`/`cn`) for constructing CSS class strings conditionally. It's a Ruby port of the JavaScript [clsx](https://github.com/lukeed/clsx) package, adapted for Ruby conventions. Framework-agnostic — works with Rails, Sinatra, Hanami, or plain Ruby.

## Common Commands

```bash
# Run all tests and linting (default rake task)
bundle exec rake

# Run tests only
bundle exec rake test

# Run a single test file
bundle exec ruby -Itest test/clsx/helper_test.rb

# Run a specific test method
bundle exec ruby -Itest test/clsx/helper_test.rb -n test_with_strings

# Run linter
bundle exec rake rubocop

# Run benchmark
bundle exec ruby benchmark/run.rb

# Install dependencies
bin/setup

# Release a new version (update version.rb first)
# Builds gem, creates git tag, pushes to rubygems.org
# OTP is fetched automatically from 1Password
bundle exec rake release
```

## Architecture

The gem has a minimal structure:

- `lib/clsx.rb` - Entry point; extends `Clsx` with `Helper`, defines `Clsx[]` and `Cn[]` shortcuts
- `lib/clsx/helper.rb` - Core implementation with `clsx` method and `cn` alias
- `lib/clsx/version.rb` - Version constant

### API

- **`Clsx['foo', bar: true]`** — primary bracket API via `self.[]`
- **`Cn['foo', bar: true]`** — short alias (defined only if `Cn` constant is not taken)
- **`Clsx.clsx(...)`** / **`Clsx.cn(...)`** — module methods
- **`include Clsx::Helper`** — mixin giving `clsx()` and `cn()` instance methods

The helper uses an optimized algorithm with fast-paths for common cases (single string, string array, simple hash) and Hash-based deduplication for complex inputs.

## Key Behaviors

- Returns `nil` (not empty string) when no classes apply — prevents rendering empty `class=""` attributes
- Eliminates duplicate classes automatically
- Ruby falsy values are only `false` and `nil` (unlike JS, `0`, `''`, `[]`, `{}` are truthy)
- Ignores `Proc`/lambda objects and boolean `true` values
- Supports complex hash keys like `{ %w[foo bar] => true }` which resolve recursively

## Benchmarking

`benchmark/original.rb` contains the **previous version** of the algorithm for comparison. It must always reflect the last committed version from the main branch — not some ancient baseline.

**Rule:** Before making any algorithm or performance change to `lib/clsx/helper.rb`, copy the current main-branch implementation into `benchmark/original.rb` (wrapping in `module ClsxOriginal` — method names stay the same, no renaming needed). This ensures `bundle exec ruby benchmark/run.rb` compares the new code against its immediate predecessor, giving meaningful before/after numbers.

## Changelog

`CHANGELOG.md` must stay current on every feature branch. After each commit, ensure the `## Unreleased` section at the top of `CHANGELOG.md` accurately reflects all user-facing changes on the branch. Add the section if it doesn't exist. Keep entries concise — one bullet per logical change. On release, the `## Unreleased` heading gets replaced with the version number.

The unreleased section describes the **net result** compared to the last release, not a history of intermediate steps. When a later change supersedes an earlier one, update or remove the stale bullet — don't accumulate entries that no longer reflect reality.

## Commit Convention

Uses [Conventional Commits](https://www.conventionalcommits.org/): `feat`, `fix`, `perf`, `chore`, `docs`, `refactor`
