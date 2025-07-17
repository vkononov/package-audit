require 'test_helper'
require 'fileutils'
require 'tempfile'
require_relative '../../../../lib/package/audit/services/config_cleaner'
require_relative '../../../../lib/package/audit/models/package'
require_relative '../../../../lib/package/audit/enum/technology'

module Package
  module Audit
    class TestConfigCleaner < Minitest::Test # rubocop:disable Metrics/ClassLength
      def setup
        @temp_dir = Dir.mktmpdir
        @config_file = File.join(@temp_dir, '.package-audit.yml')
        @custom_config_file = File.join(@temp_dir, 'custom-config.yml')
        @options = {}

        # Create some test packages
        @ruby_package1 = Package.new('test-gem', '1.0.0', Enum::Technology::RUBY)
        @ruby_package2 = Package.new('another-gem', '2.0.0', Enum::Technology::RUBY)
        @node_package1 = Package.new('test-module', '1.5.0', Enum::Technology::NODE)
        @node_package2 = Package.new('another-module', '2.5.0', Enum::Technology::NODE)

        @all_packages = [@ruby_package1, @ruby_package2, @node_package1, @node_package2]
      end

      def teardown
        FileUtils.rm_rf(@temp_dir)
      end

      def test_that_it_initializes_correctly
        config = { 'technology' => { 'ruby' => { 'test-gem' => { 'version' => '1.0.0' } } } }
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        assert_empty cleaner.removed_packages
      end

      def test_that_it_does_nothing_when_no_config_exists
        cleaner = ConfigCleaner.new(@temp_dir, nil, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_equal ['', ''], output
        refute_path_exists @config_file
      end

      def test_that_it_does_nothing_when_config_file_does_not_exist
        config = { 'technology' => { 'ruby' => { 'test-gem' => { 'version' => '1.0.0' } } } }
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_equal ['', ''], output
      end

      def test_that_it_removes_packages_with_wrong_versions # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => { 'version' => '0.9.0', 'deprecated' => false },
              'another-gem' => { 'version' => '2.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        assert_equal 1, cleaner.removed_packages.count
        assert_equal 'test-gem', cleaner.removed_packages.first[:name]
        assert_equal 'version changed from 0.9.0 to 1.0.0', cleaner.removed_packages.first[:reason]

        # Check that the config file was updated
        updated_config = YAML.load_file(@config_file)

        assert_equal ['another-gem'], updated_config['technology']['ruby'].keys
      end

      def test_that_it_removes_packages_that_no_longer_exist # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => { 'version' => '1.0.0', 'deprecated' => false },
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        assert_equal 1, cleaner.removed_packages.count
        assert_equal 'missing-gem', cleaner.removed_packages.first[:name]
        assert_equal 'package no longer exists', cleaner.removed_packages.first[:reason]

        # Check that the config file was updated
        updated_config = YAML.load_file(@config_file)

        assert_equal ['test-gem'], updated_config['technology']['ruby'].keys
      end

      def test_that_it_sorts_package_names_alphabetically # rubocop:disable Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => { 'version' => '1.0.0', 'deprecated' => false },
              'another-gem' => { 'version' => '2.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        updated_config = YAML.load_file(@config_file)
        package_names = updated_config['technology']['ruby'].keys

        assert_equal %w[another-gem test-gem], package_names
      end

      def test_that_it_sorts_package_directives_alphabetically # rubocop:disable Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => {
                'version' => '1.0.0',
                'vulnerable' => false,
                'deprecated' => false,
                'outdated' => false
              }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        updated_config = YAML.load_file(@config_file)
        package_config = updated_config['technology']['ruby']['test-gem']
        keys = package_config.keys

        assert_equal %w[version deprecated outdated vulnerable], keys
      end

      def test_that_it_works_with_multiple_technologies # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => { 'version' => '1.0.0', 'deprecated' => false },
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            },
            'node' => {
              'test-module' => { 'version' => '1.5.0', 'vulnerable' => false },
              'missing-module' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        assert_equal 2, cleaner.removed_packages.count
        removed_names = cleaner.removed_packages.map { |p| p[:name] }

        assert_includes removed_names, 'missing-gem'
        assert_includes removed_names, 'missing-module'

        # Check that the config file was updated
        updated_config = YAML.load_file(@config_file)

        assert_equal ['test-gem'], updated_config['technology']['ruby'].keys
        assert_equal ['test-module'], updated_config['technology']['node'].keys
      end

      def test_that_it_deletes_config_file_when_no_packages_remain
        config = {
          'technology' => {
            'ruby' => {
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        refute_path_exists @config_file
      end

      def test_that_it_removes_empty_technology_sections # rubocop:disable Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            },
            'node' => {
              'test-module' => { 'version' => '1.5.0', 'vulnerable' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        updated_config = YAML.load_file(@config_file)

        assert_equal ['node'], updated_config['technology'].keys
        assert_equal ['test-module'], updated_config['technology']['node'].keys
      end

      def test_that_it_prints_summary_when_format_is_not_provided
        config = {
          'technology' => {
            'ruby' => {
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_match(/Cleaned up 1 package\(s\) from \.package-audit\.yml/, output[0])
        assert_match(/missing-gem@1\.0\.0 \(ruby\): package no longer exists/, output[0])
      end

      def test_that_it_does_not_print_summary_when_format_is_provided
        @options['format'] = 'csv'
        config = {
          'technology' => {
            'ruby' => {
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_equal ['', ''], output
      end

      def test_that_it_works_with_custom_config_file # rubocop:disable Metrics/MethodLength
        @options['config'] = @custom_config_file
        config = {
          'technology' => {
            'ruby' => {
              'missing-gem' => { 'version' => '1.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@custom_config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_match(/Cleaned up 1 package\(s\) from custom-config\.yml/, output[0])
        refute_path_exists @custom_config_file
      end

      def test_that_it_does_not_modify_config_when_no_changes_needed # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => { 'version' => '1.0.0', 'deprecated' => false },
              'another-gem' => { 'version' => '2.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        original_content = File.read(@config_file)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        output = capture_io { cleaner.run }

        assert_equal 0, cleaner.removed_packages.count
        assert_equal ['', ''], output

        # Config file should be updated due to sorting
        updated_content = File.read(@config_file)

        refute_equal original_content, updated_content

        # But the structure should be preserved with sorting
        updated_config = YAML.load_file(@config_file)

        assert_equal %w[another-gem test-gem], updated_config['technology']['ruby'].keys.sort
      end

      def test_that_it_handles_malformed_config_gracefully
        config = {
          'technology' => {
            'ruby' => 'not-a-hash'
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        # Should delete the config file since no valid packages remain
        refute_path_exists @config_file
      end

      def test_that_it_handles_package_config_that_is_not_a_hash # rubocop:disable Metrics/MethodLength
        config = {
          'technology' => {
            'ruby' => {
              'test-gem' => 'not-a-hash',
              'another-gem' => { 'version' => '2.0.0', 'outdated' => false }
            }
          }
        }

        File.write(@config_file, config.to_yaml)
        cleaner = ConfigCleaner.new(@temp_dir, config, @all_packages, @options)

        capture_io { cleaner.run }

        # Should only keep the valid package
        updated_config = YAML.load_file(@config_file)

        assert_equal ['another-gem'], updated_config['technology']['ruby'].keys
      end

      private

      def capture_io
        old_stdout = $stdout
        old_stderr = $stderr
        $stdout = StringIO.new
        $stderr = StringIO.new
        yield
        [$stdout.string, $stderr.string]
      ensure
        $stdout = old_stdout
        $stderr = old_stderr
      end
    end
  end
end
