require 'test_helper'
require_relative '../../../lib/package/audit/const/fields'

require 'bundler'

module Package
  module Audit
    class TestFields < Minitest::Test
      def test_that_all_available_fields_have_headers
        assert_equal Const::Fields::AVAILABLE, Const::Fields::HEADERS.keys
      end

      def test_that_default_fields_are_a_subset_of_available_fields
        assert_empty Const::Fields::DEFAULT - Const::Fields::AVAILABLE
      end

      def test_that_the_same_fields_are_shown_for_all_reports
        headers = Const::Fields::HEADERS.slice(*Const::Fields::DEFAULT)

        deprecated_output = `bundle exec package-audit --deprecated test/files/gemfile/report`
        outdated_output = `bundle exec package-audit --outdated test/files/gemfile/report`
        default_output = `bundle exec package-audit test/files/gemfile/report`
        vulnerable_output = `bundle exec package-audit --vulnerable test/files/gemfile/report`

        headers.each_value do |value|
          assert_match value, deprecated_output
          assert_match value, outdated_output
          assert_match value, default_output
          assert_match value, vulnerable_output
        end
      end
    end
  end
end
