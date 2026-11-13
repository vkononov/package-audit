require 'test_helper'
require_relative '../../../../lib/package/audit/services/command_parser'

module Package
  module Audit
    class TestCommandParser < Minitest::Test
      def test_that_an_error_is_shown_when_config_file_not_found
        ex = assert_raises ArgumentError do
          CommandParser.new '.', { 'config' => 'unknown' }, Enum::Report::ALL
        end

        assert_equal 'Configuration file not found: unknown', ex.message
      end

      def test_that_an_error_is_shown_for_an_unsupported_technology
        ex = assert_raises ArgumentError do
          CommandParser.new '.', { 'technology' => ['invalid'] }, Enum::Report::ALL
        end

        assert_equal "\"invalid\" is not a supported technology, use one of #{Enum::Technology.all}", ex.message
      end

      def test_that_an_invalid_config_file_shows_an_error
        ex = assert_raises Psych::SyntaxError do
          CommandParser.new '.', { 'config' => 'test/files/config/.package-audit-invalid.txt' }, Enum::Report::ALL
        end

        assert_match '(test/files/config/.package-audit-invalid.txt): mapping values are not allowed in this context',
                     ex.message
      end
    end
  end
end
