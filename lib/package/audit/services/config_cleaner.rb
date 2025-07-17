require_relative '../const/file'
require_relative '../const/yaml'
require_relative '../enum/option'
require_relative '../enum/technology'

require 'yaml'
require 'json'

module Package
  module Audit
    class ConfigCleaner # rubocop:disable Metrics/ClassLength
      def initialize(dir, config, all_packages, options)
        @dir = dir
        @config = config
        @all_packages = all_packages
        @options = options
        @config_file_path = determine_config_file_path
        @removed_packages = []
      end

      def run
        return unless @config && File.exist?(@config_file_path)

        cleaned_config = clean_config

        return unless config_changed?(cleaned_config)

        write_config_file(cleaned_config)
        print_summary unless @options[Enum::Option::FORMAT]
      end

      attr_reader :removed_packages

      private

      def determine_config_file_path
        if @options[Enum::Option::CONFIG].nil?
          "#{@dir}/#{Const::File::CONFIG}"
        else
          @options[Enum::Option::CONFIG]
        end
      end

      def clean_config
        return {} unless @config

        cleaned = {}

        if @config[Const::YAML::TECHNOLOGY]
          cleaned[Const::YAML::TECHNOLOGY] = {}

          # Sort technologies alphabetically to ensure consistent ordering
          @config[Const::YAML::TECHNOLOGY].sort.each do |technology, packages|
            cleaned_packages = clean_packages_for_technology(technology, packages)
            cleaned[Const::YAML::TECHNOLOGY][technology] = cleaned_packages unless cleaned_packages.empty?
          end

          # Remove the technology key if no technologies have any packages
          cleaned.delete(Const::YAML::TECHNOLOGY) if cleaned[Const::YAML::TECHNOLOGY].empty?
        end

        cleaned
      end

      def clean_packages_for_technology(technology, packages)
        return {} unless packages.is_a?(Hash)

        current_packages = current_packages_for_technology(technology)
        cleaned_packages = {}

        packages.each do |package_name, package_config|
          next unless package_config.is_a?(Hash)

          if should_keep_package?(package_name, package_config, current_packages)
            cleaned_packages[package_name] = sort_package_config(package_config)
          else
            track_removed_package(technology, package_name, package_config)
          end
        end

        # Sort package names alphabetically
        cleaned_packages.sort.to_h
      end

      def current_packages_for_technology(technology)
        @all_packages.select { |pkg| pkg.technology == technology }
                     .to_h { |pkg| [pkg.name, pkg.version] }
      end

      def should_keep_package?(package_name, package_config, current_packages)
        config_version = package_config[Const::YAML::VERSION]
        current_version = current_packages[package_name]

        # Keep the package if it exists and the version matches
        current_version && config_version == current_version
      end

      def sort_package_config(package_config)
        sorted_config = {}

        # Add version first if it exists
        if package_config[Const::YAML::VERSION]
          sorted_config[Const::YAML::VERSION] =
            package_config[Const::YAML::VERSION]
        end

        # Add other keys in alphabetical order
        other_keys = (package_config.keys - [Const::YAML::VERSION]).sort
        other_keys.each do |key|
          sorted_config[key] = package_config[key]
        end

        sorted_config
      end

      def track_removed_package(technology, package_name, package_config)
        @removed_packages << {
          technology: technology,
          name: package_name,
          version: package_config[Const::YAML::VERSION],
          reason: determine_removal_reason(package_name, package_config)
        }
      end

      def determine_removal_reason(package_name, package_config)
        technology = find_technology_for_package(package_name)
        return 'unknown reason' unless technology

        current_packages = current_packages_for_technology(technology)
        config_version = package_config[Const::YAML::VERSION]
        current_version = current_packages[package_name]

        determine_reason_based_on_versions(package_name, technology, config_version, current_version)
      end

      def find_technology_for_package(package_name)
        @config[Const::YAML::TECHNOLOGY].each do |tech, packages|
          return tech if packages.key?(package_name)
        end
        nil
      end

      def determine_reason_based_on_versions(package_name, technology, config_version, current_version)
        if current_version.nil?
          determine_reason_for_missing_package(package_name, technology)
        elsif config_version != current_version
          "version changed from #{config_version} to #{current_version}"
        else
          'unknown reason'
        end
      end

      def determine_reason_for_missing_package(package_name, technology)
        if package_exists_in_project_files?(package_name, technology)
          'package version has changed'
        else
          'package no longer exists'
        end
      end

      def package_exists_in_project_files?(package_name, technology)
        case technology
        when Enum::Technology::RUBY
          package_exists_in_gemfile?(package_name)
        when Enum::Technology::NODE
          package_exists_in_package_json?(package_name)
        else
          false
        end
      end

      def package_exists_in_gemfile?(package_name)
        gemfile_path = "#{@dir}/#{Const::File::GEMFILE}"
        return false unless File.exist?(gemfile_path)

        gemfile_content = File.read(gemfile_path)
        # Check for gem declarations with single or double quotes
        gemfile_content.match?(/^\s*gem\s+['"]#{Regexp.escape(package_name)}['"]/)
      end

      def package_exists_in_package_json?(package_name)
        package_json_path = "#{@dir}/#{Const::File::PACKAGE_JSON}"
        return false unless File.exist?(package_json_path)

        begin
          package_json = JSON.parse(File.read(package_json_path))
          dependencies = package_json['dependencies'] || {}
          dev_dependencies = package_json['devDependencies'] || {}

          dependencies.key?(package_name) || dev_dependencies.key?(package_name)
        rescue JSON::ParserError
          false
        end
      end

      def config_changed?(cleaned_config)
        # Compare YAML representations to detect key reordering
        cleaned_config.to_yaml != @config.to_yaml
      end

      def write_config_file(cleaned_config)
        if cleaned_config.empty?
          FileUtils.rm_f(@config_file_path)
        else
          File.write(@config_file_path, cleaned_config.to_yaml)
        end
      end

      def print_summary
        return if @removed_packages.empty?

        puts
        puts "Cleaned up #{@removed_packages.count} package(s) from #{File.basename(@config_file_path)}:"

        # Sort by technology then by name for consistent output
        @removed_packages.sort_by { |pkg| [pkg[:technology], pkg[:name]] }.each do |removed_package|
          package_info = "#{removed_package[:name]}@#{removed_package[:version]}"
          tech_info = "(#{removed_package[:technology]})"
          reason = removed_package[:reason]
          puts "  - #{package_info} #{tech_info}: #{reason}"
        end
      end
    end
  end
end
