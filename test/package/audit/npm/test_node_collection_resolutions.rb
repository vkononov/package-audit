require 'test_helper'

require_relative '../../../../lib/package/audit/npm/node_collection'

module Package
  module Audit
    module Npm
      class TestNodeCollectionResolutions < Minitest::Test
        def setup
          @base_dir = Dir.pwd
        end

        def create_node_collection(dir = @base_dir)
          NodeCollection.new(dir, :all)
        end

        def test_filter_local_dependencies_method # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          dependencies = {
            'normal-package' => '^1.0.0',
            'local-module' => 'file:./local-module',
            'another-package' => '~2.3.4',
            'local-shared' => '../shared-module',
            'git-package' => 'git+https://github.com/user/repo.git',
            'local-git' => 'git+file:./local-repo',
            'link-package' => 'link:./local-link',
            'version-range' => '>=1.0.0 <2.0.0',
            'file-in-name' => 'some-file-package',
            'local-relative' => './utils'
          }

          node_collection = create_node_collection
          filtered = node_collection.send(:filter_local_dependencies, dependencies)

          # Should keep normal dependencies
          assert filtered.key?('normal-package')
          assert filtered.key?('another-package')
          assert filtered.key?('git-package')
          assert filtered.key?('version-range')
          assert filtered.key?('file-in-name')

          # Should filter out local dependencies
          refute filtered.key?('local-module')
          refute filtered.key?('local-shared')
          refute filtered.key?('local-git')
          refute filtered.key?('link-package')
          refute filtered.key?('local-relative')

          # Check the filtered count
          assert_equal 5, filtered.size
        end

        def test_filter_local_dependencies_with_empty_hash
          node_collection = create_node_collection
          filtered = node_collection.send(:filter_local_dependencies, {})

          assert_equal 0, filtered.size
        end

        def test_filter_local_dependencies_with_all_local
          all_local = {
            'local1' => 'file:./local1',
            'local2' => '../local2',
            'local3' => 'link:./local3',
            'local4' => 'git+file:./local4'
          }

          node_collection = create_node_collection
          filtered = node_collection.send(:filter_local_dependencies, all_local)

          assert_equal 0, filtered.size
        end

        def test_filter_local_dependencies_with_all_normal
          all_normal = {
            'package1' => '^1.0.0',
            'package2' => '~2.3.4',
            'package3' => 'latest',
            'package4' => 'git+https://github.com/user/repo.git'
          }

          node_collection = create_node_collection
          filtered = node_collection.send(:filter_local_dependencies, all_normal)

          assert_equal 4, filtered.size
        end

        def test_fetch_from_package_json_with_resolutions
          test_dir = File.join(@base_dir, 'test/files/with-resolutions')
          node_collection = create_node_collection(test_dir)
          default_deps, dev_deps, resolutions = node_collection.send(:fetch_from_package_json)

          # Check dependencies are read correctly
          assert_equal({'@apollo/client' => '^3.14.0', 'react' => '^18.0.0'}, default_deps)
          assert_empty(dev_deps)

          # Check resolutions are read correctly
          assert_equal({'@apollo/client' => '3.12.5', 'react' => '18.2.0'}, resolutions)
        end

        def test_fetch_from_lock_file_with_resolutions
          test_dir = File.join(@base_dir, 'test/files/with-resolutions')
          node_collection = create_node_collection(test_dir)
          pkgs = node_collection.send(:fetch_from_lock_file)

          # Check that packages use resolved versions
          apollo_client = pkgs.find { |p| p.name == '@apollo/client' }
          react = pkgs.find { |p| p.name == 'react' }

          assert_equal '3.12.5', apollo_client.version
          assert_equal '18.2.0', react.version
        end
      end
    end
  end
end
