require 'test_helper'

require_relative '../../../../lib/package/audit/npm/semver_range'

module Package
  module Audit
    module Npm
      class TestSemverRange < Minitest::Test
        def test_wildcards_match_everything
          assert_matches '*', '0.0.1'
          assert_matches 'x', '99.0.0'
          assert_matches '', '1.0.0'
          assert_matches nil, '1.0.0'
        end

        def test_exact_versions
          assert_matches '1.2.3', '1.2.3'
          assert_matches '=1.2.3', '1.2.3'
          assert_matches 'v1.2.3', '1.2.3'
          refute_matches '1.2.3', '1.2.4'
        end

        def test_simple_comparators
          assert_matches '<1.2.3', '1.2.2'
          refute_matches '<1.2.3', '1.2.3'
          assert_matches '>=1.2.3 <2.0.0', '1.9.9'
          refute_matches '>=1.2.3 <2.0.0', '2.0.0'
          refute_matches '>=1.2.3 <2.0.0', '1.2.2'
        end

        def test_partial_comparators_fill_missing_parts
          assert_matches '<1.2', '1.1.9'
          refute_matches '<1.2', '1.2.0'
          assert_matches '<=1.2', '1.2.9'
          refute_matches '<=1.2', '1.3.0'
          assert_matches '>1.2', '1.3.0'
          refute_matches '>1.2', '1.2.9'
          assert_matches '=1.2', '1.2.5'
        end

        def test_or_ranges
          range = '<1.2.3 || >=2.0.0 <2.0.5'

          assert_matches range, '1.0.0'
          assert_matches range, '2.0.4'
          refute_matches range, '1.5.0'
          refute_matches range, '2.0.5'
        end

        def test_caret_ranges
          assert_matches '^1.2.3', '1.9.0'
          refute_matches '^1.2.3', '2.0.0'
          refute_matches '^1.2.3', '1.2.2'
          assert_matches '^0.2.3', '0.2.9'
          refute_matches '^0.2.3', '0.3.0'
          assert_matches '^0.0.3', '0.0.3'
          refute_matches '^0.0.3', '0.0.4'
          assert_matches '^1.2', '1.5.0'
          assert_matches '^0', '0.9.9'
          refute_matches '^0', '1.0.0'
        end

        def test_tilde_ranges
          assert_matches '~1.2.3', '1.2.9'
          refute_matches '~1.2.3', '1.3.0'
          assert_matches '~1.2', '1.2.0'
          refute_matches '~1.2', '1.3.0'
          assert_matches '~1', '1.9.0'
          refute_matches '~1', '2.0.0'
        end

        def test_x_ranges
          assert_matches '1.2.x', '1.2.7'
          refute_matches '1.2.x', '1.3.0'
          assert_matches '1.x', '1.9.9'
          refute_matches '1.x', '2.0.0'
          assert_matches '1.2', '1.2.7'
          assert_matches '1', '1.9.9'
        end

        def test_hyphen_ranges
          assert_matches '1.2.3 - 2.3.4', '1.2.3'
          assert_matches '1.2.3 - 2.3.4', '2.3.4'
          refute_matches '1.2.3 - 2.3.4', '2.3.5'
          assert_matches '1.2.3 - 2.3', '2.3.9'
          refute_matches '1.2.3 - 2.3', '2.4.0'
          assert_matches '1.2 - 2', '2.9.9'
          refute_matches '1.2 - 2', '3.0.0'
        end

        def test_prerelease_and_build_metadata
          assert_matches '<1.0.0', '1.0.0-beta.1'
          assert_matches '>=1.0.0-alpha <1.0.0', '1.0.0-beta.1'
          assert_matches '<1.2.3', '1.2.2+build.5'
          assert_matches '<1.2.3+build', '1.2.2'
        end

        def test_unparseable_installed_version_does_not_match
          refute_matches '<1.2.3', 'not-a-version'
          refute_matches '*', 'unknown'
        end

        def test_unparseable_range_is_treated_as_matching
          assert_matches '<<<', '1.0.0'
        end

        private

        def assert_matches(range, version)
          assert SemverRange.new(range).satisfied_by?(version), "expected #{version.inspect} to match #{range.inspect}"
        end

        def refute_matches(range, version)
          refute SemverRange.new(range).satisfied_by?(version),
                 "expected #{version.inspect} not to match #{range.inspect}"
        end
      end
    end
  end
end
