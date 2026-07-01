# clsx-ruby [![Gem Version](https://img.shields.io/gem/v/clsx-ruby)](https://rubygems.org/gems/clsx-ruby) [![Codecov](https://img.shields.io/codecov/c/github/svyatov/clsx-ruby)](https://app.codecov.io/gh/svyatov/clsx-ruby) [![CI](https://github.com/svyatov/clsx-ruby/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/svyatov/clsx-ruby/actions?query=workflow%3ACI) [![GitHub License](https://img.shields.io/github/license/svyatov/clsx-ruby)](LICENSE.txt)

> The fastest, framework-agnostic conditional CSS class builder for Ruby.  
> Perfect for ViewComponent, Phlex, Tailwind CSS or just standalone.

Inspired by the JavaScript [clsx](https://github.com/lukeed/clsx) package. Works with any Ruby codebase.

## Quick Start

```bash
bundle add clsx-ruby
```

Or add it manually to the Gemfile:

```ruby
gem 'clsx-ruby', '~> 1.1'
```

Then use it:

```ruby
require 'clsx'

Clsx['btn', 'btn-primary', active: is_active, disabled: is_disabled]
# => "btn btn-primary active" (when is_active is truthy, is_disabled is falsy)
```

## Rails Integration

For Rails integration (adds `clsx` and `cn` helpers to all views), see [clsx-rails](https://github.com/svyatov/clsx-rails).

## Why clsx-ruby?

### Blazing fast

**2–4x faster** than Rails `class_names` — never slower, on realistic markup:

| Scenario | clsx-ruby | Rails `class_names` | Speedup |
|---|---|---|---|
| Token | 4.7M i/s | 1.1M i/s | **4.2x** |
| String array | 1.3M i/s | 452K i/s | **3.0x** |
| String + hash | 1.8M i/s | 610K i/s | **2.9x** |
| Utility string | 1.0M i/s | 371K i/s | **2.7x** |
| Long utility | 561K i/s | 209K i/s | **2.7x** |
| Utility + hash | 1.1M i/s | 457K i/s | **2.3x** |
| Hash | 1.9M i/s | 936K i/s | **2.0x** |

<sup>Ruby 4.0.5, Apple M1 Pro. 2.8× geomean; each row verified to produce output identical to Rails `class_names`. Reproduce: `bundle exec ruby benchmark/vs_rails.rb`</sup>

### More feature-rich than `class_names`

| Feature | clsx-ruby | Rails `class_names` |
|---|---|---|
| Conditional classes | ✅ | ✅ |
| Auto-deduplication | ✅ | ✅ |
| 2–4× faster | ✅ | ❌ |
| Returns `nil` when empty | ✅ | ❌ (returns `""`) |
| Complex hash keys | ✅ | ❌ |
| Framework-agnostic | ✅ | ❌ |
| Zero dependencies | ✅ | ❌ |

### Tiny footprint

~100 lines of code. Zero runtime dependencies. Ruby 3.2+.

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

# Symbols
Clsx[:foo, :'bar-baz']
# => 'foo bar-baz'

# Numbers
Clsx[1, 2, 3]
# => '1 2 3'

# Kitchen sink (with nesting)
Clsx['foo', ['bar', { baz: false, bat: nil }, ['hello', ['world']]], 'cya']
# => 'foo bar hello world cya'
```

## Framework Examples

### Rails

```erb
<%= tag.div class: Clsx['foo', 'baz', 'is-active': @active] do %>
  Hello, world!
<% end %>
```

### Sinatra

```ruby
erb :"<div class='#{Clsx['nav', active: @active]}'>...</div>"
```

### ViewComponent

```ruby
class AlertComponent < ViewComponent::Base
  include Clsx::Helper

  def initialize(variant: :info, dismissible: false)
    @variant = variant
    @dismissible = dismissible
  end

  def classes
    clsx("alert", "alert-#{@variant}", dismissible: @dismissible)
  end
end
```

```erb
<div class="<%= classes %>">...</div>
```

### Tailwind CSS

```ruby
class NavLink < ViewComponent::Base
  include Clsx::Helper

  def initialize(active: false)
    @active = active
  end

  def classes
    clsx(
      'px-3 py-2 rounded-md text-sm font-medium transition-colors',
      'text-white bg-indigo-600': @active,
      'text-gray-300 hover:text-white hover:bg-gray-700': !@active
    )
  end
end
```

#### Merging conflicting utilities

`clsx`/`cn` keep every class, so conflicting Tailwind utilities both survive:

```ruby
Clsx['px-2 px-4'] # => "px-2 px-4"
```

For conflict resolution, opt into the [`tailwind_merge`](https://github.com/gjtorikian/tailwind_merge)
gem. Add it to your `Gemfile` (clsx-ruby itself stays dependency-free), then require the
integration once at boot:

```ruby
# config/initializers/clsx.rb
require 'clsx/tailwind_merge'

# Optional: configure the merger (prefix, cache size, custom theme, …)
Clsx.merger = TailwindMerge::Merger.new(config: { prefix: 'tw' })
```

This adds a merged variant — `twm` / `Twm[]` — the last conflicting utility wins.
`clsx`/`cn` stay pure; only `twm`/`Twm` merge:

```ruby
Twm['px-2 px-4']                       # => "px-4"
Twm['p-4', 'p-2', 'bg-red', 'bg-blue'] # => "p-2 bg-blue"
Clsx['px-2 px-4']                      # => "px-2 px-4" (unchanged)

# Also available as a mixin method and a module method:
include Clsx::Helper
twm('px-2 px-4')       # => "px-4"
Clsx.twm('px-2 px-4')  # => "px-4"
```

### Phlex

```ruby
class Badge < Phlex::HTML
  include Clsx::Helper

  def initialize(color: :blue, pill: false)
    @color = color
    @pill = pill
  end

  def view_template
    span(class: clsx("badge", "badge-#{@color}", pill: @pill)) { yield }
  end
end
```

## Differences from JavaScript clsx

1. **Returns `nil`** when no classes apply (not an empty string). This prevents rendering empty `class=""` attributes in template engines that skip `nil`:
   ```ruby
   Clsx[nil, false] # => nil
   ```

2. **Deduplication** — Duplicate classes are automatically removed, even across multi-token strings:
   ```ruby
   Clsx['foo', 'foo']      # => 'foo'
   Clsx['foo bar', 'foo']  # => 'foo bar'
   ```

3. **Falsy values** — In Ruby only `false` and `nil` are falsy, so `0`, `''`, `[]`, `{}` are all truthy:
   ```ruby
   Clsx['foo' => 0, bar: []] # => 'foo bar'
   ```

4. **Complex hash keys** — Any valid `clsx` input works as a hash key:
   ```ruby
   Clsx[[{ foo: true }, 'bar'] => true] # => 'foo bar'
   ```

5. **Ignored values** — Boolean `true` and `Proc`/lambda objects are silently ignored:
   ```ruby
   Clsx['', proc {}, -> {}, nil, false, true] # => nil
   ```

## Development

```bash
bin/setup                             # install dependencies
bundle exec rake test                 # run tests
bundle exec ruby benchmark/run.rb    # run benchmarks
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/svyatov/clsx-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
