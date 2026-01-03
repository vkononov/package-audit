require 'test_helper'
require 'stringio'

require_relative '../../../lib/package/audit/const/fields'
require_relative '../../../lib/package/audit/enum/format'
require_relative '../../../lib/package/audit/util/bash_color'
require_relative '../../../lib/package/audit/services/package_printer'
require_relative '../../../lib/package/audit/formatter/vulnerability'
require_relative '../../../lib/package/audit/models/package'

module Package
  module Audit
    class TestPrinter < Minitest::Test
      def setup # rubocop:disable Metrics/MethodLength
        @today = Time.now.strftime('%Y-%m-%d')
        @fileutils = Package.new 'fileutils', '1.5.0', 'ruby'
        @fileutils.update latest_version: '1.7.1', latest_version_date: @today, groups: %w[default]
        @rails = Package.new 'rails', '6.0.0', 'ruby'
        @rails.update latest_version: '7.0.4.3', latest_version_date: @today, groups: %w[default],
                      vulnerabilities: [
                        Enum::VulnerabilityType::MEDIUM,
                        Enum::VulnerabilityType::HIGH,
                        Enum::VulnerabilityType::HIGH
                      ]
        @puma = Package.new 'puma', '5.1.1', 'ruby'
        @puma.update latest_version: '5.1.1', latest_version_date: '2020-12-10', groups: %w[development test]
        @gems = [@fileutils, @puma, @rails]

        @output = StringIO.new
        $stdout = @output
      end

      def teardown
        $stdout = STDOUT
      end

      def test_that_an_error_is_shown_for_invalid_fields
        fields = %i[name version unknown]
        exp_error = "[:invalid] are not valid field names. Available fields names are: #{Const::Fields::DEFAULT}."
        assert_raises ArgumentError, exp_error do
          PackagePrinter.new({}, []).print(fields)
        end
      end

      def test_that_the_dependencies_are_displayed_correctly # rubocop:disable Metrics/AbcSize
        PackagePrinter.new({}, @gems).print(%i[name version latest_version latest_version_date])
        lines = @output.string.split("\n")

        assert_equal 7, lines.length
        assert_includes lines[0], '─'
        assert_equal ' Package    Version  Latest   Latest Date', lines[1]
        assert_includes lines[2], '─'
        assert_equal " fileutils  1.#{Util::BashColor.yellow('5.0')}    1.7.1    #{@today} ", lines[3]
        assert_equal " puma       5.1.1    5.1.1    #{Util::BashColor.yellow('2020-12-10')} ", lines[4]
        assert_equal " rails      #{Util::BashColor.orange('6.0.0')}    7.0.4.3  #{@today} ", lines[5]
        assert_includes lines[6], '─'
      end

      def test_that_the_dependencies_are_displayed_correctly_in_markdown # rubocop:disable Metrics/AbcSize
        options = {Enum::Option::FORMAT => Enum::Format::MARKDOWN}
        PackagePrinter.new(options, @gems).print(%i[name version latest_version latest_version_date])
        lines = @output.string.split("\n")

        assert_equal 5, lines.length
        assert_equal '| Package   | Version | Latest  | Latest Date |', lines[0]
        assert_equal '|:----------|:--------|:--------|:------------|', lines[1]
        assert_equal "| fileutils | 1.#{Util::BashColor.yellow('5.0')}   | 1.7.1   | #{@today}  |", lines[2]
        assert_equal "| puma      | 5.1.1   | 5.1.1   | #{Util::BashColor.yellow('2020-12-10')}  |", lines[3]
        assert_equal "| rails     | #{Util::BashColor.orange('6.0.0')}   | 7.0.4.3 | #{@today}  |", lines[4]
      end

      def test_that_the_dependencies_are_displayed_correctly_in_csv_with_headers # rubocop:disable Metrics/AbcSize
        options = {Enum::Option::FORMAT => Enum::Format::CSV}
        columns = %i[name version latest_version flags]
        PackagePrinter.new(options, @gems).print(columns)
        lines = @output.string.split("\n")

        assert_equal @gems.length + 1, lines.length
        assert_equal columns.join(','), lines[0]

        @gems.each_with_index do |gem, index|
          assert_equal "#{gem.name},#{gem.version},#{gem.latest_version},#{gem.flags}", lines[index + 1]
        end
      end

      def test_that_vulnerabilities_are_displayed_correctly
        PackagePrinter.new({}, [@rails]).print(%i[vulnerabilities])
        lines = @output.string.split("\n")

        assert_equal " #{Formatter::Vulnerability.new(@rails.vulnerabilities).format}", lines[3]
      end

      def test_that_vulnerabilities_are_displayed_correctly_in_csv
        options = {Enum::Option::FORMAT => Enum::Format::CSV}
        PackagePrinter.new(options, [@rails]).print(%i[vulnerabilities])
        lines = @output.string.split("\n")

        assert_equal 'medium(1) high(2)', lines[1]
      end
    end
  end
end
