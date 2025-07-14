require 'test_helper'

require_relative '../../../lib/package/audit/npm/node_collection'

module Package
  module Audit
    class TestLocalDependencyIntegration < Minitest::Test
      def test_npm_local_dependencies_are_filtered_in_package_json_parsing # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # Test with our custom test directory that has local dependencies
        test_dir = 'test/files/with-local-deps'

        node_collection = Package::Audit::Npm::NodeCollection.new(test_dir, :all)

        # Call the private method to test package.json parsing
        default_deps, dev_deps = node_collection.send(:fetch_from_package_json)

        # Verify local dependencies are filtered out
        refute default_deps.key?(:'local-module'), 'local-module should be filtered'
        refute default_deps.key?(:'shared-utils'), 'shared-utils should be filtered'
        refute default_deps.key?(:'link-package'), 'link-package should be filtered'
        refute default_deps.key?(:'git-local'), 'git-local should be filtered'
        refute dev_deps.key?(:'local-dev'), 'local-dev should be filtered'

        # Verify normal dependencies are kept
        assert default_deps.key?(:'normal-package'), 'normal-package should be kept'
        assert default_deps.key?(:semver), 'semver should be kept'
        assert dev_deps.key?(:jest), 'jest should be kept'

        # Verify values are preserved
        assert_equal '^1.0.0', default_deps[:'normal-package']
        assert_equal '^6.3.0', default_deps[:semver]
        assert_equal '^29.0.0', dev_deps[:jest]
      end

      def test_local_dependency_patterns_are_detected_correctly
        node_collection = Package::Audit::Npm::NodeCollection.new('.', :all)

        # Test all the local dependency patterns
        local_patterns = %w[file:./local-module file:../shared-module file:/absolute/path/to/module link:./local-module
                            ./local-module ../shared-module git+file:./local-git-repo some-package-with-file:stuff]

        local_patterns.each do |pattern|
          assert node_collection.send(:local_dependency?, pattern),
                 "Pattern '#{pattern}' should be detected as local dependency"
        end

        # Test normal dependency patterns
        normal_patterns = %w[^1.0.0 ~2.3.4 >=1.0.0 latest git+https://github.com/user/repo.git https://github.com/user/repo/archive/master.tar.gz]

        normal_patterns.each do |pattern|
          refute node_collection.send(:local_dependency?, pattern),
                 "Pattern '#{pattern}' should NOT be detected as local dependency"
        end
      end

      def test_filter_dependencies_removes_only_local_ones # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        node_collection = Package::Audit::Npm::NodeCollection.new('.', :all)

        mixed_deps = {
          'react' => '^18.0.0',
          'local-utils' => 'file:./utils',
          'lodash' => '^4.17.21',
          'shared-lib' => '../shared-lib',
          'express' => '~4.18.0',
          'local-git' => 'git+file:./local-git-repo',
          'remote-git' => 'git+https://github.com/user/repo.git'
        }

        filtered = node_collection.send(:filter_local_dependencies, mixed_deps)

        # Should keep normal dependencies
        assert_equal '^18.0.0', filtered['react']
        assert_equal '^4.17.21', filtered['lodash']
        assert_equal '~4.18.0', filtered['express']
        assert_equal 'git+https://github.com/user/repo.git', filtered['remote-git']

        # Should remove local dependencies
        refute filtered.key?('local-utils')
        refute filtered.key?('shared-lib')
        refute filtered.key?('local-git')

        # Should have exactly 4 dependencies left
        assert_equal 4, filtered.size
      end

      def test_empty_dependencies_are_handled_correctly
        node_collection = Package::Audit::Npm::NodeCollection.new('.', :all)

        # Test with empty hash
        filtered = node_collection.send(:filter_local_dependencies, {})

        assert_equal 0, filtered.size

        # Test with nil (should be converted to string)
        refute node_collection.send(:local_dependency?, nil)

        # Test with empty string
        refute node_collection.send(:local_dependency?, '')
      end
    end
  end
end
