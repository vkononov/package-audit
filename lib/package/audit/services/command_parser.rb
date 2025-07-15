require_relative '../const/cmd'
require_relative '../const/file'
require_relative '../enum/option'
require_relative '../enum/report'
require_relative '../technology/detector'
require_relative '../technology/validator'
require_relative '../util/spinner'
require_relative '../util/summary_printer'
require_relative 'package_finder'
require_relative 'package_printer'

require 'yaml'

module Package
  module Audit
    class CommandParser # rubocop:disable Metrics/ClassLength
      def initialize(dir, options, report)
        @dir = dir
        @options = options
        @report = report
        @config = parse_config_file!
        @groups = @options[Enum::Option::GROUP]
        @technologies = parse_technologies!
        validate_format!
        @spinner = Util::Spinner.new("Evaluating packages and their dependencies for #{human_readable_technologies}...")
      end

      def run
        if File.file? @dir.to_s
          raise "\"#{@dir}\" is a file instead of directory"
        elsif !File.directory? @dir.to_s
          raise "\"#{@dir}\" is not a valid directory"
        elsif @technologies.empty?
          raise 'No supported technologies found in this directory'
        else
          process_technologies
        end
      end

      private

      def process_technologies # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        mutex = Mutex.new
        cumulative_pkgs = []
        thread_index = 0

        @spinner.start
        threads = @technologies.map.with_index do |technology, technology_index|
          Thread.new do
            all_pkgs, ignored_pkgs = PackageFinder.new(@config, @dir, @report, @groups).run(technology)
            ignored_pkgs = [] if @options[Enum::Option::INCLUDE_IGNORED]
            cumulative_pkgs += (all_pkgs || []) - (ignored_pkgs || [])
            sleep 0.1 while technology_index != thread_index # print each technology in order
            mutex.synchronize do
              @spinner.stop
              print_results(technology, (all_pkgs || []) - (ignored_pkgs || []), ignored_pkgs || [])
              thread_index += 1
              @spinner.start
            end
          rescue StandardError => e
            Thread.current[:exception] = e
          end
        end
        threads.each do |thread|
          thread.join
          raise thread[:exception] if thread[:exception]
        end
        cumulative_pkgs.any? ? 1 : 0
      ensure
        @spinner.stop
      end

      def print_results(technology, pkgs, ignored_pkgs)
        PackagePrinter.new(@options, pkgs).print(Const::Fields::DEFAULT)
        print_summary(technology, pkgs, ignored_pkgs) unless @options[Enum::Option::FORMAT] == Enum::Format::CSV
        print_disclaimer(technology) unless @options[Enum::Option::FORMAT] || pkgs.empty?
      end

      def print_summary(technology, pkgs, ignored_pkgs)
        if @report == Enum::Report::ALL
          Util::SummaryPrinter.statistics(@options[Enum::Option::FORMAT], technology, @report, pkgs, ignored_pkgs)
        else
          Util::SummaryPrinter.total(technology, @report, pkgs, ignored_pkgs)
        end
      end

      def print_disclaimer(technology)
        case @report
        when Enum::Report::DEPRECATED
          Util::SummaryPrinter.deprecated
        when Enum::Report::ALL, Enum::Report::VULNERABLE
          Util::SummaryPrinter.vulnerable(technology, learn_more_command(technology))
        end
      end

      def learn_more_command(technology)
        case technology
        when Enum::Technology::RUBY
          Const::Cmd::BUNDLE_AUDIT
        when Enum::Technology::NODE
          Const::Cmd::YARN_AUDIT
        else
          raise ArgumentError, "Unexpected technology \"#{technology}\" found in #{__method__}"
        end
      end

      def parse_config_file!
        if @options[Enum::Option::CONFIG].nil?
          YAML.load_file("#{@dir}/#{Const::File::CONFIG}") if File.exist? "#{@dir}/#{Const::File::CONFIG}"
        elsif File.exist? @options[Enum::Option::CONFIG]
          YAML.load_file(@options[Enum::Option::CONFIG])
        else
          raise ArgumentError, "Configuration file not found: #{@options[Enum::Option::CONFIG]}"
        end
      end

      def validate_format!
        format = @options[Enum::Option::FORMAT]
        raise ArgumentError, "Invalid format: #{format}, should be one of [#{Enum::Format.all.join('|')}]" unless
          @options[Enum::Option::FORMAT].nil? || Enum::Format.all.include?(format)
      end

      def parse_technologies!
        technology_validator = Technology::Validator.new(@dir)
        @options[Enum::Option::TECHNOLOGY]&.each { |technology| technology_validator.validate! technology }
        (@options[Enum::Option::TECHNOLOGY] || Technology::Detector.new(@dir).detect).sort
      end

      def human_readable_technologies
        array = @technologies.map(&:capitalize)
        return '' if array.nil?
        return array.join if array.size <= 1
        return array.join(' and ') if array.size == 2

        "#{array[0..-2].join(', ')}, and #{array.last}"
      end
    end
  end
end
