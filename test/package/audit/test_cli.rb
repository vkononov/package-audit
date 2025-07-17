require 'test_helper'
require_relative '../../../lib/package/audit/enum/format'
require_relative '../../../lib/package/audit/enum/technology'
require_relative '../../../lib/package/audit/util/risk_legend'
require_relative '../../../lib/package/audit/version'
require 'bundler'

module Package
  module Audit
    class Cli < Minitest::Test
      def setup
        @config_file = 'test/files/config/.package-audit.yml'
        backup_config_file
      end

      def teardown
        restore_config_file
      end

      def test_that_it_version_command_works
        output = `bundle exec package-audit --version`

        assert_match VERSION, output
      end

      def test_that_it_risk_command_works
        output = `bundle exec package-audit risk`

        stdout = StringIO.new
        $stdout = stdout
        Util::RiskLegend.print
        $stdout = STDOUT

        assert_equal stdout.string, output
      end

      def test_that_help_command_works
        output = `bundle exec package-audit help`

        assert_match 'Commands:', output
      end

      def test_that_unknown_commands_give_an_appropriate_error
        output = `bundle exec package-audit invalid`

        assert_match '"invalid" is not a valid directory', output
      end

      def test_that_that_config_option_works
        output = `bundle exec package-audit test/files/gemfile/empty --config test/files/config/.package-audit.yml`

        assert_match 'There are no deprecated, outdated or vulnerable Ruby packages!', output
      end

      def test_that_that_config_option_alias_works
        output = `bundle exec package-audit test/files/gemfile/empty -c test/files/config/.package-audit.yml`

        assert_match 'There are no deprecated, outdated or vulnerable Ruby packages!', output
      end

      def test_that_that_config_option_returns_an_appropriate_error
        output = `bundle exec package-audit test/files/gemfile/empty -c test/files/config/invalid`

        assert_match 'Configuration file not found: test/files/config/invalid', output
      end

      def test_that_that_include_ignored_option_works
        output = `bundle exec package-audit test/files/gemfile/empty --include-ignored`

        assert_match 'There are no deprecated, outdated or vulnerable Ruby packages!', output
      end

      def test_that_that_exclude_headers_option_works
        output = `bundle exec package-audit test/files/gemfile/empty --exclude-headers`

        assert_match 'There are no deprecated, outdated or vulnerable Ruby packages!', output
      end

      def test_that_that_format_option_works
        output = `bundle exec package-audit test/files/gemfile/empty --format invalid`

        assert_match "Invalid format: invalid, should be one of [#{Enum::Format.all.join('|')}]", output
      end

      def test_that_that_format_option_alias_works
        output = `bundle exec package-audit test/files/gemfile/empty -f invalid`

        assert_match "Invalid format: invalid, should be one of [#{Enum::Format.all.join('|')}]", output
      end

      def test_that_that_technology_option_works
        output = `bundle exec package-audit test/files/gemfile/empty --technology invalid`

        assert_match "\"invalid\" is not a supported technology, use one of #{Enum::Technology.all}", output
      end

      private

      def backup_config_file
        return unless File.exist?(@config_file)

        @config_backup = File.read(@config_file)
      end

      def restore_config_file
        return unless @config_backup

        File.write(@config_file, @config_backup)
      end
    end
  end
end
