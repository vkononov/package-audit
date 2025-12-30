require 'test_helper'

module Package
  module Audit
    class TestSpacing < Minitest::Test
      TEST_DIR = 'test/files/spacing'

      # Helper to strip ANSI codes and spinner output
      def clean_output(output)
        output
          .gsub(/\e\[[0-9;]*m/, '')                    # Strip ANSI color codes
          .gsub(/\r[^\n]*(?=\r|\n)/, '')               # Remove spinner lines (end with \r not \n)
          .delete("\r") # Remove remaining carriage returns
      end

      # ==================== PRETTY FORMAT ====================

      def test_pretty_format_all
        output = `bundle exec package-audit #{TEST_DIR}`
        clean = clean_output(output)

        # Pretty format should have leading space before summary messages
        assert_match(/^ \d+ ⦗V⦘ulnerable/, clean, 'Summary should have leading space in pretty format')
        assert_match(/^ Found a total of \d+ Node packages\./, clean, 'Node total should have leading space')
        assert_match(/^ Found a total of \d+ Ruby packages\./, clean, 'Ruby total should have leading space')

        # Should have disclaimer after Node packages total
        assert_match(/Node packages\.\n.*For more information/m, clean, 'Should have disclaimer after Node total')
      end

      def test_pretty_format_deprecated
        output = `bundle exec package-audit --deprecated #{TEST_DIR}`
        clean = clean_output(output)

        # Check for summary with leading space
        assert_match(/^ Found a total of \d+ (Node|Ruby) packages\.|^ There are no deprecated/, clean)
      end

      def test_pretty_format_vulnerable
        output = `bundle exec package-audit --vulnerable #{TEST_DIR}`
        clean = clean_output(output)

        # Check for summary or "no packages" message with leading space
        assert_match(/^ Found a total of \d+ (Node|Ruby) packages\.|^ There are no vulnerable/, clean)
      end

      def test_pretty_format_outdated
        output = `bundle exec package-audit --outdated #{TEST_DIR}`
        clean = clean_output(output)

        # Check for summary with leading space
        assert_match(/^ Found a total of \d+ (Node|Ruby) packages\.|^ There are no outdated/, clean)
      end

      # ==================== MARKDOWN FORMAT ====================

      def test_markdown_format_all
        output = `bundle exec package-audit -f md #{TEST_DIR}`
        clean = clean_output(output)

        # Markdown should NOT have leading spaces before summaries
        assert_match(/^\d+ ⦗V⦘ulnerable/, clean, 'Summary should NOT have leading space in markdown')
        assert_match(/^Found a total of \d+ Node packages\./, clean, 'Node total should NOT have leading space')
        assert_match(/^Found a total of \d+ Ruby packages\./, clean, 'Ruby total should NOT have leading space')

        # Should have blank line between table and summary stats
        assert_match(/\|\n\n\d+ ⦗V⦘ulnerable/m, clean, 'Should have blank line between table and summary')

        # Both Node and Ruby tables should exist
        assert_match(/\| Package\s+\|/, clean, 'Should have table headers')
      end

      def test_markdown_format_deprecated
        output = `bundle exec package-audit -f md --deprecated #{TEST_DIR}`
        clean = clean_output(output)

        if clean.include?('Found a total of')
          # No leading space on summary
          assert_match(/^Found a total of \d+ (Node|Ruby) packages\./m, clean, 'No leading space')
        else
          # "No packages" message should not have leading space
          assert_match(/^There are no deprecated/m, clean, 'No leading space on message')
        end
      end

      def test_markdown_format_vulnerable
        output = `bundle exec package-audit -f md --vulnerable #{TEST_DIR}`
        clean = clean_output(output)

        if clean.include?('Found a total of')
          assert_match(/^Found a total of \d+ (Node|Ruby) packages\./m, clean, 'No leading space')
        end

        # Check "no packages" message doesn't have leading space
        return unless clean.include?('There are no vulnerable')

        assert_match(/^There are no vulnerable/m, clean, 'No leading space on message')
      end

      def test_markdown_format_outdated
        output = `bundle exec package-audit -f md --outdated #{TEST_DIR}`
        clean = clean_output(output)

        return unless clean.include?('Found a total of')

        assert_match(/^Found a total of \d+ (Node|Ruby) packages\./m, clean, 'No leading space')
      end

      # ==================== CSV FORMAT ====================

      def test_csv_format_all
        output = `bundle exec package-audit -f csv #{TEST_DIR}`
        clean = clean_output(output)

        # CSV should not have summary messages
        refute_match(/Found a total of/, clean, 'CSV should not have summary messages')
        refute_match(/⦗V⦘ulnerable.*⦗O⦘utdated.*⦗D⦘eprecated/, clean, 'CSV should not have statistics')

        # CSV should have header
        assert_match(/^name,version/m, clean, 'CSV should have header')

        # Should have data rows
        assert_match(/esbuild/, clean, 'CSV should have Node package data')
        assert_match(/nokogiri/, clean, 'CSV should have Ruby package data')
      end

      def test_csv_format_deprecated
        output = `bundle exec package-audit -f csv --deprecated #{TEST_DIR}`
        clean = clean_output(output)

        # CSV should not have summary messages
        refute_match(/Found a total of/, clean, 'CSV should not have summary messages')

        # Should have header if there's content
        assert_match(/^name,version/m, clean, 'CSV should have header') if clean.strip.length.positive?
      end

      def test_csv_format_vulnerable
        output = `bundle exec package-audit -f csv --vulnerable #{TEST_DIR}`
        clean = clean_output(output)

        # CSV should not have summary messages
        refute_match(/Found a total of/, clean, 'CSV should not have summary messages')
      end

      def test_csv_format_outdated
        output = `bundle exec package-audit -f csv --outdated #{TEST_DIR}`
        clean = clean_output(output)

        # CSV should not have summary messages
        refute_match(/Found a total of/, clean, 'CSV should not have summary messages')
      end
    end
  end
end
