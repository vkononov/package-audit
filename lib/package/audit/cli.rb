require_relative 'const/file'
require_relative 'const/time'
require_relative 'enum/format'
require_relative 'enum/option'
require_relative 'services/command_parser'
require_relative 'util//risk_legend'
require_relative 'version'

require 'json'
require 'thor'

module Package
  module Audit
    class CLI < Thor
      default_task :default

      class_option Enum::Option::DEPRECATED,
                   type: :boolean,
                   desc: 'Filter to show only deprecated packages (or use --skip-deprecated to exclude them)'
      class_option Enum::Option::OUTDATED,
                   type: :boolean,
                   desc: 'Filter to show only outdated packages (or use --skip-outdated to exclude them)'
      class_option Enum::Option::VULNERABLE,
                   type: :boolean,
                   desc: 'Filter to show only vulnerable packages (or use --skip-vulnerable to exclude them)'
      class_option Enum::Option::TECHNOLOGY,
                   aliases: '-t', repeatable: true,
                   desc: 'Technology to be audited (repeat this flag for each technology)'
      class_option Enum::Option::GROUP,
                   aliases: '-g', repeatable: true,
                   desc: 'Group to be audited (repeat this flag for each group)'
      class_option Enum::Option::CONFIG,
                   aliases: '-c', banner: 'FILE',
                   desc: "Path to a custom configuration file, default: #{Const::File::CONFIG})"
      class_option Enum::Option::INCLUDE_IGNORED,
                   type: :boolean, default: false,
                   desc: 'Include packages ignored by a configuration file'
      class_option Enum::Option::FORMAT,
                   aliases: '-f', banner: Enum::Format.all.join('|'), type: :string,
                   desc: 'Output reports using a different format (e.g. CSV or Markdown)'
      class_option Enum::Option::CSV_EXCLUDE_HEADERS,
                   type: :boolean, default: false,
                   desc: "Hide headers when using the #{Enum::Format::CSV} format"

      map '-v' => :version
      map '--version' => :version

      desc '[DIR]', 'Show a report of potentially deprecated, outdated or vulnerable packages'
      def default(dir = Dir.pwd)
        report = determine_report_type
        within_rescue_block { exit CommandParser.new(dir, options, report).run }
      end

      desc 'risk', 'Print information on how risk is calculated'
      def risk
        Util::RiskLegend.print
      end

      desc 'version', 'Print the currently installed version of the package-audit gem'
      def version
        puts "package-audit #{VERSION}"
      end

      def self.exit_on_failure?
        true
      end

      def method_missing(command, *args)
        invoke :default, [command], args
      end

      def respond_to_missing?
        true
      end

      private

      def determine_report_type # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        deprecated = options[Enum::Option::DEPRECATED]
        outdated = options[Enum::Option::OUTDATED]
        vulnerable = options[Enum::Option::VULNERABLE]

        # Count positive filters (true) and negative filters (false)
        positive_filters = [deprecated, outdated, vulnerable].count(true)
        negative_filters = [deprecated, outdated, vulnerable].count(false)

        # If any explicit filters are set (positive or negative), we need to filter
        # Otherwise all are nil (not specified) and we show everything
        has_explicit_filters = [deprecated, outdated, vulnerable].any? { |v| !v.nil? }

        # If no filters specified at all, return ALL
        return Enum::Report::ALL unless has_explicit_filters

        # If only positive filters, handle them
        if positive_filters.positive? && negative_filters.zero?
          # Single positive filter - use specific report type
          return Enum::Report::DEPRECATED if positive_filters == 1 && deprecated
          return Enum::Report::OUTDATED if positive_filters == 1 && outdated
          return Enum::Report::VULNERABLE if positive_filters == 1 && vulnerable

          # Multiple positive filters - fetch ALL and filter in CommandParser
          return Enum::Report::ALL
        end

        # If we have any filters (positive or negative), fetch ALL and filter in CommandParser
        Enum::Report::ALL
      end

      def within_rescue_block
        yield
      rescue StandardError => e
        exit_with_error "#{e.class}: #{e.message}"
      end

      def exit_with_error(msg)
        puts Util::BashColor.red msg
        exit 1
      end
    end
  end
end
