# frozen_string_literal: true

require 'test_helper'
require 'clsx/tailwind_merge'

module Clsx
  class TailwindMergeTest < Minitest::Test
    include Helper

    def teardown
      Clsx.merger = nil # reset to the lazy default between tests
    end

    def test_twm_resolves_conflicts_via_every_entry_point
      assert_equal 'px-4', twm('px-2 px-4')       # mixin
      assert_equal 'px-4', Clsx.twm('px-2 px-4')  # module method
      assert_equal 'px-4', Twm['px-2 px-4']       # bracket shortcut
    end

    def test_twm_merges_conditional_arguments
      assert_equal 'px-4', twm('px-2', 'px-4', hidden: false)
    end

    def test_twm_returns_nil_when_empty
      assert_nil twm(nil, false)
      assert_nil Twm[nil]
    end

    def test_clsx_and_cn_stay_pure
      assert_equal 'px-2 px-4', clsx('px-2 px-4')
      assert_equal 'px-2 px-4', cn('px-2 px-4')
      assert_equal 'px-2 px-4', Clsx['px-2 px-4']
      assert_equal 'px-2 px-4', Cn['px-2 px-4']
    end

    def test_custom_merger_is_used
      Clsx.merger = TailwindMerge::Merger.new(config: { prefix: 'tw' })

      # With the `tw` prefix configured, only prefixed utilities conflict.
      assert_equal 'tw:px-4', twm('tw:px-2 tw:px-4')
    end
  end
end
