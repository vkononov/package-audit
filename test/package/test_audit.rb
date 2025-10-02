require 'test_helper'
require_relative '../../lib/package/audit/util/summary_printer'
require_relative '../../lib/package/audit/version'

require 'bundler'

module Package
  class TestAudit < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil Package::Audit::VERSION
    end

    def test_that_there_is_a_success_message_when_report_is_empty
      output = `bundle exec package-audit test/files/gemfile/empty`

      assert_match 'There are no deprecated, outdated or vulnerable Ruby packages!', output
    end

    def test_that_there_is_a_success_with_ignored_packages_message_when_report_is_empty
      output = `bundle exec package-audit test/files/gemfile/ignored_empty`

      assert_match '0 vulnerable, 0 outdated, 0 deprecated (1 ignored).', output
      assert_match 'There are no deprecated, outdated or vulnerable Ruby packages (1 ignored)!', output
    end

    def test_that_there_is_a_success_with_ignored_packages_message_when_report_is_not_empty
      output = `bundle exec package-audit test/files/gemfile/ignored`

      assert_match '0 vulnerable, 1 outdated, 0 deprecated (1 ignored).', output
      assert_match 'Found a total of 1 Ruby packages (1 ignored).', output
    end

    def test_that_there_is_a_success_message_when_everything_is_up_to_date
      output = `bundle exec package-audit outdated test/files/gemfile/empty`

      assert_match 'There are no outdated Ruby packages!', output
    end

    def test_that_there_is_a_success_message_when_there_are_no_vulnerabilities
      output = `bundle exec package-audit vulnerable test/files/gemfile/empty`

      assert_match 'There are no vulnerable Ruby packages!', output
    end

    def test_that_there_is_a_success_message_when_there_are_no_deprecations
      output = `bundle exec package-audit deprecated test/files/gemfile/empty`

      assert_match 'There are no deprecated Ruby packages!', output
    end

    def test_that_the_exit_code_is_0_when_report_is_empty
      assert system('bundle exec package-audit test/files/gemfile/empty')
    end

    def test_that_the_exit_code_is_1_when_report_is_not_empty
      refute system('bundle exec package-audit test/files/gemfile/report')
    end

    def test_that_there_is_a_report_of_gems
      output = `bundle exec package-audit test/files/gemfile/report`

      assert_match 'Found a total of 3 Ruby packages.', output
      assert_match '1 vulnerable (17 vulnerabilities), 2 outdated, 1 deprecated.', output
    end

    def test_that_there_is_a_message_about_outdated_gems
      output = `bundle exec package-audit outdated test/files/gemfile/outdated`

      assert_match 'Found a total of 1 Ruby packages.', output
    end

    def test_that_there_is_a_message_about_deprecated_gems
      output = `bundle exec package-audit deprecated test/files/gemfile/deprecated`

      assert_match 'Found a total of 1 Ruby packages.', output
    end

    def test_that_there_is_a_message_about_vulnerable_gems
      output = `bundle exec package-audit vulnerable test/files/gemfile/vulnerable`

      assert_match 'Found a total of 1 Ruby packages.', output
    end

    def test_that_there_is_a_report_of_node_modules_with_no_dependencies
      output = `bundle exec package-audit test/files/yarn/empty`

      assert_match 'There are no deprecated, outdated or vulnerable Node packages!', output
    end

    def test_that_there_is_a_report_of_node_modules_formatted_by_npm_with_no_dependencies
      output = `bundle exec package-audit test/files/yarn/npm`

      assert_match 'Found a total of 1 Node packages.', output
    end

    def test_that_there_is_a_success_message_when_node_modules_are_up_to_date
      output = `bundle exec package-audit outdated test/files/yarn/empty`

      assert_match 'There are no outdated Node packages!', output
    end

    def test_that_there_is_a_success_message_when_node_modules_have_no_vulnerabilities
      output = `bundle exec package-audit vulnerable test/files/yarn/empty`

      assert_match 'There are no vulnerable Node packages!', output
    end

    def test_that_there_is_a_success_message_when_node_modules_have_no_deprecations
      output = `bundle exec package-audit deprecated test/files/yarn/empty`

      assert_match 'There are no deprecated Node packages!', output
    end

    def test_that_there_is_a_report_of_node_modules
      output = `bundle exec package-audit test/files/yarn/report`

      assert_match '1 vulnerable (1 vulnerabilities), 2 outdated, 1 deprecated.', output
    end

    def test_that_there_is_a_message_about_outdated_node_modules
      output = `bundle exec package-audit outdated test/files/yarn/outdated`

      assert_match 'Found a total of 3 Node packages.', output
    end

    def test_that_there_is_a_message_about_deprecated_node_modules
      output = `bundle exec package-audit deprecated test/files/yarn/deprecated`

      assert_match 'Found a total of 1 Node packages.', output
    end

    def test_that_there_is_a_message_about_vulnerable_node_modules
      output = `bundle exec package-audit outdated test/files/yarn/vulnerable`

      assert_match 'Found a total of 1 Node packages.', output
    end
  end
end
