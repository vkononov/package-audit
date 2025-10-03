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

      class_option Enum::Option::CONFIG,
                   aliases: '-c', banner: 'FILE',
                   desc: "Path to a custom configuration file, default: #{Const::File::CONFIG})"
      class_option Enum::Option::GROUP,
                   aliases: '-g', repeatable: true,
                   desc: 'Group to be audited (repeat this flag for each group)'
      class_option Enum::Option::TECHNOLOGY,
                   aliases: '-t', repeatable: true,
                   desc: 'Technology to be audited (repeat this flag for each technology)'
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
        within_rescue_block { exit CommandParser.new(dir, options, Enum::Report::ALL).run }
      end

      desc 'deprecated [DIR]',
           "Show packages with no updates by author for at least #{Const::Time::YEARS_ELAPSED_TO_BE_OUTDATED} years"
      def deprecated(dir = Dir.pwd)
        within_rescue_block { exit CommandParser.new(dir, options, Enum::Report::DEPRECATED).run }
      end

      desc 'outdated [DIR]', 'Show packages that are out of date'
      def outdated(dir = Dir.pwd)
        within_rescue_block { exit CommandParser.new(dir, options, Enum::Report::OUTDATED).run }
      end

      desc 'vulnerable [DIR]', 'Show packages and their dependencies that have security vulnerabilities'
      def vulnerable(dir = Dir.pwd)
        within_rescue_block { exit CommandParser.new(dir, options, Enum::Report::VULNERABLE).run }
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
