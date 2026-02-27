# frozen_string_literal: true

require 'test_helper'

module Clsx
  class HelperTest < Minitest::Test
    include Helper

    def test_it_eliminates_duplicates
      assert_equal 'foo bar', clsx('foo', 'bar', 'foo')
      assert_equal 'foo bar', clsx('foo', 'bar', %w[foo bar])
      assert_equal(
        'a b 1 2 3 4 foo bar',
        clsx(
          [[[['a'], 'b']]],
          { a: 1, b: 2 },
          [1, 2, 3, 4],
          { [1, 2, { %w[foo bar] => true }] => true }
        )
      )
    end

    # Source: https://github.com/lukeed/clsx/blob/master/test/index.js
    def test_with_strings
      assert_nil clsx('')
      assert_equal 'foo bar', clsx('foo', 'bar')
      assert_equal 'foo baz', clsx(true && 'foo', false && 'bar', 'baz')
      assert_equal 'bar baz', clsx(false && 'foo', 'bar', 'baz', '')
    end

    def test_with_numbers
      assert_equal '1', clsx(1)
      assert_equal '12', clsx(12)
      assert_equal '0.1', clsx(0.1)
      assert_equal '0', clsx(0)
      assert_equal 'Infinity', clsx(Float::INFINITY)
      assert_equal 'NaN', clsx(Float::NAN)
    end

    def test_with_variadic_numbers
      assert_equal '1 2', clsx(1, 2)
      assert_equal '1 2 3', clsx(1, 2, 3)
      assert_equal '1 2 3 4', clsx(1, 2, 3, 4)
    end

    def test_with_hashes
      assert_nil clsx({})
      assert_equal 'foo', clsx(foo: true)
      assert_equal 'foo', clsx(foo: true, bar: false)
      assert_equal 'foo bar', clsx(foo: 'hiya', bar: 1)
      assert_equal 'foo baz', clsx(foo: 1, bar: nil, baz: 1)
      assert_equal '-foo --bar', clsx('-foo': 1, '--bar': 1)
      assert_equal 'foo bar', clsx([:foo, { bar: true }] => true)
    end

    def test_with_variadic_hashes
      assert_nil clsx({}, {})
      assert_equal 'foo bar', clsx({ foo: 1 }, { bar: 2 })
      assert_equal 'foo baz', clsx({ foo: 1 }, nil, { baz: 1, bat: nil })
      assert_equal 'foo bar bat', clsx({ foo: 1 }, {}, {}, { bar: 'a' }, { baz: nil, bat: Float::INFINITY })
    end

    def test_with_arrays
      assert_nil clsx([])
      assert_equal 'foo', clsx(['foo'])
      assert_equal 'foo bar', clsx(%w[foo bar])
      assert_equal 'foo baz', clsx(['foo', false && 'bar', 1 && 'baz'])
    end

    def test_with_nested_arrays
      assert_nil clsx([[[]]])
      assert_equal 'foo', clsx([[['foo']]])
      assert_equal 'foo', clsx([true, [['foo']]])
      assert_equal 'foo bar baz', clsx(['foo', ['bar', ['', [['baz']]]]])
    end

    def test_with_variadic_arrays
      assert_nil clsx([], [])
      assert_equal 'foo bar', clsx(['foo'], ['bar'])
      assert_equal 'foo baz', clsx(['foo'], nil, ['baz', ''], true, '', [])
    end

    def test_with_procs_and_lambdas
      foo = -> {}
      bar = proc {}
      assert_nil clsx(foo)
      assert_equal 'hello', clsx(foo, 'hello')
      assert_equal 'hello', clsx(foo, 'hello', bar)
      assert_equal 'hello world', clsx(bar, 'hello', [[foo], 'world'])
      assert_equal 'hello world', clsx({ foo => true }, 'hello', [{ foo => false }, 'world'], nil)
    end

    def test_with_mixed_types
      assert_nil clsx(nil, false, '', {}, [])
      assert_equal 'foo bar', clsx(nil, false, '', { foo: true }, ['bar'])
    end

    def test_with_no_arguments
      assert_nil clsx
    end

    def test_with_single_symbol
      assert_equal 'foo', clsx(:foo)
      assert_equal 'foo-bar', clsx(:'foo-bar')
    end

    def test_with_single_array_duplicates_and_empty
      # Tests the fast path for single array of strings with duplicates and empty strings
      assert_equal 'foo bar', clsx(%w[foo bar foo])
      assert_equal 'foo bar', clsx(['foo', '', 'bar', ''])
      assert_equal 'foo', clsx(['foo', '', 'foo'])
    end

    def test_with_string_keys_in_hash
      assert_equal 'foo', clsx('foo' => true)
      assert_equal 'foo bar', clsx('foo' => true, 'bar' => 1)
      assert_equal 'foo', clsx('foo' => true, 'bar' => false)
      # Empty string key should be filtered out
      assert_nil clsx('' => true)
      assert_equal 'foo', clsx('' => true, 'foo' => true)
    end

    def test_with_single_hash_all_falsy
      assert_nil clsx(foo: false)
      assert_nil clsx(foo: nil, bar: false)
      assert_nil clsx('foo' => false)
    end

    def test_with_complex_key_in_single_hash
      # Complex key that evaluates to empty
      assert_nil clsx({ [''] => true })
      assert_nil clsx({ [[[]]] => true })
      # Complex key with valid content
      assert_equal 'foo', clsx({ %w[foo] => true })
      # Hash-as-key
      assert_equal 'a', clsx({ { a: true } => true })
      assert_equal 'a b', clsx({ { a: true } => true, { b: 1 } => true })
    end

    def test_with_custom_objects
      obj = Object.new
      def obj.to_s = 'custom-class'

      assert_equal 'custom-class', clsx(obj)
      assert_equal 'custom-class', clsx([obj])
      assert_equal 'foo custom-class', clsx('foo', [obj])

      # Object with empty to_s should be filtered
      empty_obj = Object.new
      def empty_obj.to_s = ''

      assert_nil clsx(empty_obj)
      assert_nil clsx([empty_obj])
      assert_equal 'foo', clsx('foo', [empty_obj])

      # Custom object as hash key
      assert_equal 'custom-class', clsx({ obj => true })
      assert_equal 'custom-class foo', clsx({ obj => true, foo: true })
    end

    # Source: https://github.com/lukeed/clsx/blob/master/test/classnames.js
    def test_compatiblity_with_classnames
      # (compat) keeps object keys with truthy values
      assert_equal 'a c e', clsx(a: true, b: false, c: 0, d: nil, e: 1)

      # (compat) joins arrays of class names and ignore falsy values
      assert_equal 'a 0 1 b', clsx('a', 0, nil, true, 1, 'b')

      # (compat) supports heterogeneous arguments
      assert_equal 'a b', clsx({ a: true }, 'b', false)

      # (compat) should be trimmed
      assert_equal 'b', clsx('', 'b', {}, '')

      # (compat) joins array arguments with string arguments
      assert_equal 'a b c', clsx(%w[a b], 'c')
      assert_equal 'c a b', clsx('c', %w[a b])

      # (compat) handles multiple array arguments
      assert_equal 'a b c d', clsx(%w[a b], %w[c d])

      # (compat) handles arrays that include falsy and true values
      assert_equal 'a b', clsx(['a', nil, false, true, 'b'])

      # (compat) handles arrays that include objects
      assert_equal 'a b', clsx(['a', { b: true, c: false }])

      # (compat) handles deep array recursion
      assert_equal 'a b c d', clsx(['a', ['b', ['c', { d: true }]]])

      # (compat) handles arrays that are empty
      assert_equal 'a', clsx('a', [])

      # (compat) handles nested arrays that have empty nested arrays
      assert_equal 'a', clsx('a', [[]])

      # (compat) handles all types of truthy and falsy property values as expected
      falsy_values = {
        null: nil,
        falseClass: false
      }

      truthy_values = {
        infinity: Float::INFINITY,
        zero: 0,
        negativeZero: -0,
        emptyString: '',
        nonEmptyString: 'foobar',
        emptyHash: {},
        nonEmptyHash: { a: 1, b: 2 },
        emptyArray: [],
        nonEmptyArray: [1, 2, 3],
        number: 1,
        proc: proc {},
        lambda: -> {},
        method: Object.instance_method(:to_s),
        object: Object.new,
        class: Class.new
      }

      expected = truthy_values.keys.join(' ')

      assert_equal expected, clsx(falsy_values, truthy_values)
    end

    def test_single_string_dedup
      assert_equal 'btn btn-active', clsx('btn btn-active btn')
      assert_equal 'a b c', clsx('a b c b a')
      assert_equal 'foo', clsx('foo foo foo')
      # No duplicates — returns original
      assert_equal 'btn btn-primary', clsx('btn btn-primary')
    end

    def test_single_symbol_dedup
      assert_equal 'btn btn-active', clsx(:'btn btn-active btn')
      assert_equal 'a b c', clsx(:'a b c b a')
    end

    def test_hash_symbol_key_with_spaces
      assert_equal 'btn active', clsx('btn btn': true, active: true)
      assert_equal 'a b', clsx('a b': true)
    end

    def test_str_hash_symbol_key_with_spaces
      assert_equal 'base btn', clsx('base', 'btn btn': true)
      assert_equal 'btn btn-primary active btn-lg', clsx('btn btn-primary', 'active btn-lg': true)
    end

    def test_cross_argument_dedup_with_multi_token_strings
      assert_equal 'foo bar', clsx('foo bar', 'foo')
      assert_equal 'foo bar', clsx('foo bar', 'bar')
      assert_equal 'foo bar baz', clsx('foo bar', 'baz', 'foo')
      assert_equal 'a b c d', clsx('a b c', 'b c d')
    end

    def test_string_hash_dedup_with_multi_token_base
      assert_equal 'btn btn-primary active', clsx('btn btn btn-primary', active: true)
      assert_equal 'btn btn-primary', clsx('btn btn-primary', btn: true)
      assert_equal 'btn btn-primary active', clsx('btn btn-primary', active: true, btn: true)
      assert_equal 'btn btn-primary', clsx('btn btn-primary', 'btn' => true)
      assert_equal 'btn-primary btn', clsx('btn-primary', btn: true) # partial match — no dedup
      # String keys in str+hash
      assert_equal 'btn active', clsx('btn', 'active' => true)
      assert_equal 'btn', clsx('btn', 'btn' => true)
      # Complex key in str+hash
      assert_equal 'btn foo', clsx('btn', %w[foo] => true)
      # String keys in str+hash full (multi-token base)
      assert_equal 'btn btn-primary active', clsx('btn btn-primary', 'active' => true)
      # Complex key in str+hash full
      assert_equal 'btn btn-primary foo', clsx('btn btn-primary', %w[foo] => true)
    end

    def test_simple_hash_with_space_in_string_key
      assert_equal 'foo bar', clsx('foo bar' => true, 'foo' => true)
      assert_equal 'a b', clsx('a b' => true)
    end

    def test_single_array_with_multi_token_strings
      assert_equal 'foo bar', clsx(['foo bar', 'foo'])
      assert_equal 'a b c d', clsx(['a b c', 'b c d'])
    end

    # --- Cross-type deduplication ---

    def test_string_and_symbol_key_dedup_in_hash
      assert_equal 'a', clsx('a' => true, a: true)
      assert_equal 'a b', clsx('a' => true, a: true, b: true)
    end

    def test_string_and_symbol_arg_dedup
      assert_equal 'foo', clsx('foo', :foo)
      assert_equal 'foo', clsx(:foo, 'foo')
      assert_equal 'foo bar', clsx(:foo, 'bar', 'foo', :bar)
    end

    def test_string_arg_and_hash_key_dedup
      assert_equal 'foo', clsx('foo', foo: true)
      assert_equal 'foo', clsx('foo', 'foo' => true)
      assert_equal 'foo', clsx(:foo, 'foo' => true)
    end

    def test_array_and_hash_dedup
      assert_equal 'foo', clsx(['foo'], foo: true)
      assert_equal 'foo bar', clsx(%w[foo bar], foo: true, bar: true)
    end

    def test_nested_array_dedup_against_top_level
      assert_equal 'foo', clsx('foo', [['foo']])
      assert_equal 'foo bar', clsx('foo', [['bar', ['foo']]])
    end

    def test_symbol_and_string_in_array_dedup
      assert_equal 'foo', clsx([:foo, 'foo'])
      assert_equal 'foo bar', clsx([:foo, 'bar', 'foo', :bar])
    end

    def test_numeric_and_string_dedup
      assert_equal '1', clsx(1, '1')
      assert_equal '0 1', clsx(0, '1', 1, '0')
    end

    # --- Multi-token key self-dedup ---

    def test_multi_token_string_key_self_dedup
      assert_equal 'hello', clsx('hello hello' => true)
      assert_equal 'a b', clsx('a b a b a' => true)
    end

    def test_multi_token_symbol_key_self_dedup
      assert_equal 'hello', clsx('hello hello': true)
      assert_equal 'a b', clsx('a b a b a': true)
    end

    def test_multi_token_key_dedup_across_keys
      assert_equal 'a b c', clsx('a b' => true, 'b c' => true)
      assert_equal 'a b c', clsx('a b': true, 'b c': true)
    end

    # --- Mixed-type multi-token dedup ---

    def test_multi_token_dedup_across_arg_types
      assert_equal 'a b c d', clsx('a b', ['b c'], { c: true, d: true })
      assert_equal 'foo bar baz', clsx('foo bar', :baz, ['foo'], bar: true)
    end

    # --- Whitespace handling ---

    def test_whitespace_only_strings
      assert_nil clsx('   ')
      assert_nil clsx(' ')
      assert_nil clsx("\t")
      assert_nil clsx("\n")
      assert_nil clsx("\t\n  ")
    end

    def test_whitespace_only_strings_in_arrays
      assert_nil clsx(['   '])
      assert_nil clsx([' ', '  '])
      assert_equal 'foo', clsx(['   ', 'foo'])
    end

    def test_whitespace_only_hash_keys
      assert_nil clsx(' ' => true)
      assert_nil clsx('   ' => true)
      assert_nil clsx(' ': true)
      assert_equal 'foo', clsx(' ' => true, 'foo' => true)
    end

    def test_leading_trailing_whitespace_normalization
      assert_equal 'foo', clsx(' foo ')
      assert_equal 'foo bar', clsx(' foo bar ')
      assert_equal 'foo bar', clsx('foo ', ' bar')
    end

    def test_consecutive_space_normalization
      assert_equal 'foo bar', clsx('foo  bar')
      assert_equal 'foo bar baz', clsx('foo  bar  baz')
    end

    def test_tab_and_newline_as_whitespace
      assert_equal 'foo bar', clsx("foo\tbar")
      assert_equal 'foo bar', clsx("foo\nbar")
      assert_equal 'foo bar', clsx("foo\t\nbar")
    end

    def test_tab_in_hash_key_with_multi_token_base
      # str+hash full path: tab-containing keys must be normalized
      assert_equal 'foo bar a b', clsx('foo bar', "a\tb": true)
      assert_equal 'foo bar', clsx('foo bar', "foo\tbar": true)
      assert_equal 'foo bar a b', clsx('foo bar', "a\nb": true)
      assert_equal 'foo bar a b', clsx('foo bar', "a\tb" => true)
    end

    def test_tab_in_base_string_with_hash
      # tab-containing base string should be normalized
      assert_equal 'a b foo', clsx("a\tb", foo: true)
      assert_equal 'a b', clsx("a\tb", a: true)
    end

    def test_whitespace_only_symbol
      assert_nil clsx(:'  ')
      assert_nil clsx(:"\t")
    end

    # --- Module-level API tests ---

    def test_clsx_bracket_api
      assert_equal 'foo bar', Clsx['foo', bar: true]
      assert_equal 'foo', Clsx['foo', bar: false]
      assert_nil Clsx[nil, false]
      assert_equal 'a b c', Clsx['a', %w[b c]]
    end

    def test_clsx_module_methods
      assert_equal 'foo bar', Clsx.clsx('foo', 'bar')
      assert_equal 'foo bar', Clsx.cn('foo', 'bar')
      assert_nil Clsx.clsx
      assert_nil Clsx.cn
    end

    def test_cn_short_alias
      assert_equal 'foo bar', Cn['foo', bar: true]
      assert_equal 'foo', Cn['foo', bar: false]
      assert_nil Cn[nil, false]
    end

    def test_cn_alias_delegates_to_clsx
      assert_equal Clsx['foo', bar: true], Cn['foo', bar: true]
    end
  end
end
