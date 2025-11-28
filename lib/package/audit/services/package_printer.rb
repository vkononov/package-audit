require_relative '../const/fields'
require_relative '../enum/option'
require_relative '../formatter/risk'
require_relative '../formatter/version'
require_relative '../formatter/version_date'
require_relative '../formatter/vulnerability'

module Package
  module Audit
    class PackagePrinter
      BASH_FORMATTING_REGEX = /\e\[\d+(?:;\d+)*m/

      COLUMN_GAP = 2

      def initialize(options, pkgs)
        @options = options
        @pkgs = pkgs
      end

      def print(fields)
        check_fields(fields)
        return if @pkgs.empty?

        case @options[Enum::Option::FORMAT]
        when Enum::Format::CSV
          csv(fields, exclude_headers: @options[Enum::Option::CSV_EXCLUDE_HEADERS])
          puts
        when Enum::Format::MARKDOWN
          markdown(fields)
          puts
        else
          pretty(fields)
        end
      end

      private

      def check_fields(fields)
        return unless (fields - Const::Fields::DEFAULT).any?

        raise ArgumentError,
              "#{fields - Const::Fields::DEFAULT} are not valid field names. " \
              "Available fields names are: #{Const::Fields::DEFAULT}."
      end

      def pretty(fields = Const::Fields::DEFAULT) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        max_widths = get_field_max_widths(fields)
        header = fields.map.with_index do |field, index|
          Const::Fields::HEADERS[field].gsub(BASH_FORMATTING_REGEX, '').ljust(max_widths[index])
        end.join(' ' * COLUMN_GAP)
        separator_plain = max_widths.map { |width| '─' * width }.join('─' * COLUMN_GAP)
        separator = Util::BashColor.light_green(separator_plain)

        puts ' '
        puts ' ' + separator
        puts ' ' + header
        puts ' ' + separator

        @pkgs.each do |pkg|
          puts ' ' + fields.map.with_index { |key, index|
            val = get_field_value(pkg, key)
            formatting_length = val.length - val.gsub(BASH_FORMATTING_REGEX, '').length
            val.ljust(max_widths[index] + formatting_length)
          }.join(' ' * COLUMN_GAP)
        end

        puts ' ' + separator
      end

      def csv(fields = Const::Fields::DEFAULT, exclude_headers: false)
        puts fields.join(',') unless exclude_headers
        @pkgs.map do |pkg|
          puts fields.map { |field| get_field_value(pkg, field) }.join(',').gsub(BASH_FORMATTING_REGEX, '')
        end
      end

      def markdown(fields = Const::Fields::DEFAULT) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        max_widths = get_field_max_widths(fields)
        header = fields.map.with_index do |field, index|
          Const::Fields::HEADERS[field].gsub(BASH_FORMATTING_REGEX, '').ljust(max_widths[index])
        end.join(' | ')
        separator = max_widths.map { |width| ":#{'-' * width}" }.join('-|')

        puts "| #{header} |"
        puts "|#{separator}-|"

        @pkgs.each do |pkg|
          row = fields.map.with_index do |key, index|
            val = get_field_value(pkg, key)
            formatting_length = val.length - val.gsub(BASH_FORMATTING_REGEX, '').length
            val.ljust(max_widths[index] + formatting_length)
          end
          puts "| #{row.join(' | ')} |"
        end
      end

      def get_field_max_widths(fields)
        # Calculate the maximum width for each column, including header titles and content
        fields.map do |field|
          [@pkgs.map do |pkg|
            value = get_field_value(pkg, field).to_s.gsub(BASH_FORMATTING_REGEX, '').length
            value
          end.max, Const::Fields::HEADERS[field].gsub(BASH_FORMATTING_REGEX, '').length].max
        end
      end

      def get_field_value(pkg, field)
        case field
        when :risk_type
          Formatter::Risk.new(pkg.risk_type).format
        when :version
          Formatter::Version.new(pkg.version, pkg.latest_version).format
        when :vulnerabilities
          Formatter::Vulnerability.new(pkg.vulnerabilities).format
        when :latest_version_date
          Formatter::VersionDate.new(pkg.latest_version_date).format
        else
          pkg.send(field) || ''
        end
      end
    end
  end
end
