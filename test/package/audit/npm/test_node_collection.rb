require 'test_helper'

require_relative '../../../../lib/package/audit/npm/node_collection'

module Package
  module Audit
    module Npm
      class TestNodeCollection < Minitest::Test
        def setup
          @node_collection = NodeCollection.new(Dir.pwd, :all)
        end

        def test_local_dependency_detection_file_protocol
          # Test file: protocol variations
          assert @node_collection.send(:local_dependency?, 'file:./local-module')
          assert @node_collection.send(:local_dependency?, 'file:../shared-module')
          assert @node_collection.send(:local_dependency?, 'file:/absolute/path/to/module')
          assert @node_collection.send(:local_dependency?, 'file:///absolute/path/to/module')
        end

        def test_local_dependency_detection_link_protocol
          # Test link: protocol
          assert @node_collection.send(:local_dependency?, 'link:./local-module')
          assert @node_collection.send(:local_dependency?, 'link:../shared-module')
        end

        def test_local_dependency_detection_relative_paths
          # Test relative paths
          assert @node_collection.send(:local_dependency?, './local-module')
          assert @node_collection.send(:local_dependency?, '../shared-module')
          assert @node_collection.send(:local_dependency?, './some/nested/path')
          assert @node_collection.send(:local_dependency?, '../some/nested/path')
        end

        def test_local_dependency_detection_git_with_file
          # Test git repositories with local file paths
          assert @node_collection.send(:local_dependency?, 'git+file:./local-git-repo')
          assert @node_collection.send(:local_dependency?, 'git+file:../shared-git-repo')
          assert @node_collection.send(:local_dependency?, 'git+file:///absolute/path/to/repo')
        end

        def test_local_dependency_detection_mixed_file_paths
          # Test packages with "file:" somewhere in the string
          assert @node_collection.send(:local_dependency?, 'some-package-with-file:stuff')
          assert @node_collection.send(:local_dependency?, 'git+https://github.com/user/repo.git#file:path')
        end

        def test_normal_dependency_detection
          # Test that normal dependencies are not filtered
          refute @node_collection.send(:local_dependency?, '^1.0.0')
          refute @node_collection.send(:local_dependency?, '~2.3.4')
          refute @node_collection.send(:local_dependency?, '>=1.0.0')
          refute @node_collection.send(:local_dependency?, '1.0.0')
          refute @node_collection.send(:local_dependency?, 'latest')
          refute @node_collection.send(:local_dependency?, 'next')
          refute @node_collection.send(:local_dependency?, 'beta')
          refute @node_collection.send(:local_dependency?, '1.0.0-alpha.1')
        end

        def test_git_remote_repositories_not_filtered
          # Test that remote git repositories are not filtered
          refute @node_collection.send(:local_dependency?, 'git+https://github.com/user/repo.git')
          refute @node_collection.send(:local_dependency?, 'git+ssh://git@github.com/user/repo.git')
          refute @node_collection.send(:local_dependency?, 'git://github.com/user/repo.git')
          refute @node_collection.send(:local_dependency?, 'https://github.com/user/repo/archive/master.tar.gz')
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

          filtered = @node_collection.send(:filter_local_dependencies, dependencies)

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
          filtered = @node_collection.send(:filter_local_dependencies, {})

          assert_equal 0, filtered.size
        end

        def test_filter_local_dependencies_with_all_local
          all_local = {
            'local1' => 'file:./local1',
            'local2' => '../local2',
            'local3' => 'link:./local3',
            'local4' => 'git+file:./local4'
          }

          filtered = @node_collection.send(:filter_local_dependencies, all_local)

          assert_equal 0, filtered.size
        end

        def test_filter_local_dependencies_with_all_normal
          all_normal = {
            'package1' => '^1.0.0',
            'package2' => '~2.3.4',
            'package3' => 'latest',
            'package4' => 'git+https://github.com/user/repo.git'
          }

          filtered = @node_collection.send(:filter_local_dependencies, all_normal)

          assert_equal 4, filtered.size
        end

        def test_local_dependency_edge_cases
          # Test edge cases
          refute @node_collection.send(:local_dependency?, '')
          refute @node_collection.send(:local_dependency?, nil)

          # Test symbols (should be converted to string)
          assert @node_collection.send(:local_dependency?, :'file:./local')
          refute @node_collection.send(:local_dependency?, :'^1.0.0')
        end
      end
    end
  end
end
