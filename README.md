# clsx-ruby [![Gem Version](https://img.shields.io/gem/v/clsx-ruby)](https://rubygems.org/gems/clsx-ruby) [![CI](https://github.com/svyatov/clsx-ruby/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/svyatov/clsx-ruby/actions?query=workflow%3ACI) [![GitHub License](https://img.shields.io/github/license/svyatov/clsx-ruby)](LICENSE.txt)

> A tiny, framework-agnostic utility for constructing CSS class strings conditionally.

Ruby port of the JavaScript [clsx](https://github.com/lukeed/clsx) package. Works with Rails, Sinatra, Hanami, or plain Ruby.

For automatic Rails view helper integration, see [clsx-rails](https://github.com/svyatov/clsx-rails).

## Requirements

Ruby 3.2+. No runtime dependencies.

## Installation

```bash
bundle add clsx-ruby
```

Or add it manually to the Gemfile:

```ruby
gem 'clsx-ruby', '~> 1.0'
```

## Usage

### Bracket API (recommended)

```ruby
require 'clsx'

Clsx['foo', 'bar']
# => 'foo bar'

Clsx['foo', bar: true, baz: false]
# => 'foo bar'

Clsx['btn', 'btn-primary', active: is_active, disabled: is_disabled]
# => 'btn btn-primary active' (when is_active is truthy, is_disabled is falsy)
```

### Short alias

```ruby
Cn['foo', bar: true]
# => 'foo bar'
```

`Cn` is defined only if the constant is not already taken.

### Mixin

```ruby
include Clsx::Helper

clsx('foo', 'bar')
# => 'foo bar'

cn(hidden: @hidden, 'text-bold': @bold)
# => 'hidden text-bold' (when both are truthy)
```

### Module methods

```ruby
Clsx.clsx('foo', 'bar')
# => 'foo bar'

Clsx.cn('foo', bar: true)
# => 'foo bar'
```

### Input types

```ruby
# Strings (variadic)
Clsx['foo', true && 'bar', 'baz']
# => 'foo bar baz'

# Hashes
Clsx[foo: true, bar: false, baz: a_truthy_method]
# => 'foo baz'

# Hashes (variadic)
Clsx[{ foo: true }, { bar: false }, nil, { '--foobar': 'hello' }]
# => 'foo --foobar'

# Arrays
Clsx[['foo', nil, false, 'bar']]
# => 'foo bar'

# Arrays (variadic)
Clsx[['foo'], ['', nil, false, 'bar'], [['baz', [['hello'], 'there']]]]
# => 'foo bar baz hello there'

# Kitchen sink (with nesting)
Clsx['foo', ['bar', { baz: false, bat: nil }, ['hello', ['world']]], 'cya']
# => 'foo bar hello world cya'
```

### Framework examples

```erb
<%# Rails %>
<%= tag.div class: Clsx['foo', 'baz', 'is-active': @active] do %>
  Hello, world!
<% end %>
```

```ruby
# Sinatra
erb :"<div class='#{Clsx['nav', active: @active]}'>...</div>"
```

## Differences from JavaScript clsx

1. **Falsy values** — In Ruby only `false` and `nil` are falsy, so `0`, `''`, `[]`, `{}` are all truthy:
   ```ruby
   Clsx['foo' => 0, bar: []] # => 'foo bar'
   ```

2. **Complex hash keys** — Any valid `clsx` input works as a hash key:
   ```ruby
   Clsx[[{ foo: true }, 'bar'] => true] # => 'foo bar'
   ```

3. **Ignored values** — Boolean `true` and `Proc`/lambda objects are silently ignored:
   ```ruby
   Clsx['', proc {}, -> {}, nil, false, true] # => nil
   ```

4. **Returns `nil`** when no classes apply (not an empty string). This prevents rendering empty `class=""` attributes in template engines that skip `nil`:
   ```ruby
   Clsx[nil, false] # => nil
   ```

5. **Deduplication** — Duplicate classes are automatically removed:
   ```ruby
   Clsx['foo', 'foo'] # => 'foo'
   ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

There is a benchmark suite in the `benchmark` directory. Run it with `bundle exec ruby benchmark/run.rb`.

## Conventional Commits

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.

Types: `feat`, `fix`, `perf`, `chore`, `docs`, `refactor`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/svyatov/clsx-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
