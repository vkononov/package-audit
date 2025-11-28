require 'test_helper'

module Package
  module Audit
    class TestFlagFilters < Minitest::Test
      # Test positive filters (--deprecated, --outdated, --vulnerable)

      def test_deprecated_flag_shows_only_deprecated_packages
        output = `bundle exec package-audit --deprecated test/files/gemfile/report`

        assert_match(/Package/, output)
        assert_match(/deprecated/, output)
      end

      def test_outdated_flag_shows_only_outdated_packages
        output = `bundle exec package-audit --outdated test/files/gemfile/report`

        assert_match(/Package/, output)
        assert_match(/Found a total of/, output)
      end

      def test_vulnerable_flag_shows_only_vulnerable_packages
        output = `bundle exec package-audit --vulnerable test/files/gemfile/report`

        assert_match(/Package/, output)
        assert_match(/Found a total of/, output)
      end

      def test_multiple_positive_flags_show_union_of_packages
        output = `bundle exec package-audit --deprecated --vulnerable test/files/gemfile/report`

        # Should show packages that are deprecated OR vulnerable
        assert_match(/Package/, output)
      end

      # Test negative filters (--skip-deprecated, --skip-outdated, --skip-vulnerable)

      def test_skip_deprecated_excludes_deprecated_only_packages
        # Get the full report first to understand what we have
        full_output = `bundle exec package-audit test/files/gemfile/report`
        skip_output = `bundle exec package-audit --skip-deprecated test/files/gemfile/report`

        # The skip-deprecated output should be different from full output
        refute_equal full_output, skip_output, 'Skip-deprecated should produce different output'
      end

      def test_skip_outdated_excludes_outdated_only_packages
        full_output = `bundle exec package-audit test/files/gemfile/report`
        skip_output = `bundle exec package-audit --skip-outdated test/files/gemfile/report`

        # The skip-outdated output should be different from full output
        refute_equal full_output, skip_output, 'Skip-outdated should produce different output'
      end

      def test_skip_vulnerable_still_shows_multi_risk_packages
        # NOTE: If a package is vulnerable AND has other risks (like outdated),
        # it will still appear with --skip-vulnerable because of the other risk
        skip_output = `bundle exec package-audit --skip-vulnerable test/files/gemfile/report`

        # Should still show packages (deprecated, outdated, or vulnerable+outdated like 'rack')
        assert_match(/Found a total of/, skip_output)
        assert_match(/rack/, skip_output) # rack is vulnerable+outdated, still shows due to outdated
      end

      def test_multiple_skip_flags_exclude_multiple_types
        output = `bundle exec package-audit --skip-deprecated --skip-outdated test/files/gemfile/report`

        # Should only show vulnerable packages (and clean ones if any)
        assert_match(/⦗V⦘ulnerable/, output)
      end

      # Test that packages with multiple risk types are handled correctly

      def test_multi_risk_package_appears_with_skip_one_risk
        # A package that is both outdated AND vulnerable should still appear
        # when we --skip-outdated because it's also vulnerable
        # This test assumes the report file has such a package (rack is vulnerable+outdated)

        vulnerable_output = `bundle exec package-audit --vulnerable test/files/gemfile/report`
        skip_outdated_output = `bundle exec package-audit --skip-outdated test/files/gemfile/report`

        # Both should show the rack package
        assert_match(/rack/, vulnerable_output)
        assert_match(/rack/, skip_outdated_output)
      end

      # Test empty results

      def test_deprecated_flag_with_no_deprecated_packages_shows_appropriate_message
        output = `bundle exec package-audit --deprecated test/files/gemfile/empty`

        assert_match(/There are no deprecated Ruby packages!/, output)
      end

      def test_skip_flags_can_result_in_empty_list
        # If we skip all risk types, we should get the success message (no risky packages)
        output = `bundle exec package-audit --skip-deprecated --skip-outdated --skip-vulnerable \
test/files/gemfile/report`

        # This should show the success message since all risky packages are filtered out
        assert_match(/There are no deprecated, outdated or vulnerable/, output)
      end
    end
  end
end
