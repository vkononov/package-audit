require 'test_helper'

require_relative '../../../../lib/package/audit/npm/node_collection'

module Package
  module Audit
    module Npm
      class TestNodeCollectionDependencies < Minitest::Test
        def setup
          @base_dir = Dir.pwd
        end

        def create_node_collection(dir = @base_dir)
          NodeCollection.new(dir, :all)
        end

        def test_local_dependency_detection_file_protocol
          # Test file: protocol variations
          node_collection = create_node_collection

          assert node_collection.send(:local_dependency?, 'file:./local-module')
          assert node_collection.send(:local_dependency?, 'file:../shared-module')
          assert node_collection.send(:local_dependency?, 'file:/absolute/path/to/module')
          assert node_collection.send(:local_dependency?, 'file:///absolute/path/to/module')
        end

        def test_local_dependency_detection_link_protocol
          # Test link: protocol
          node_collection = create_node_collection

          assert node_collection.send(:local_dependency?, 'link:./local-module')
          assert node_collection.send(:local_dependency?, 'link:../shared-module')
        end

        def test_local_dependency_detection_relative_paths
          # Test relative paths
          node_collection = create_node_collection

          assert node_collection.send(:local_dependency?, './local-module')
          assert node_collection.send(:local_dependency?, '../shared-module')
          assert node_collection.send(:local_dependency?, './some/nested/path')
          assert node_collection.send(:local_dependency?, '../some/nested/path')
        end

        def test_local_dependency_detection_git_with_file
          # Test git repositories with local file paths
          node_collection = create_node_collection

          assert node_collection.send(:local_dependency?, 'git+file:./local-git-repo')
          assert node_collection.send(:local_dependency?, 'git+file:../shared-git-repo')
          assert node_collection.send(:local_dependency?, 'git+file:///absolute/path/to/repo')
        end

        def test_local_dependency_detection_mixed_file_paths
          # Test packages with "file:" somewhere in the string
          node_collection = create_node_collection

          assert node_collection.send(:local_dependency?, 'some-package-with-file:stuff')
          assert node_collection.send(:local_dependency?, 'git+https://github.com/user/repo.git#file:path')
        end

        def test_normal_dependency_detection
          test_version_ranges
          test_exact_versions
          test_special_versions
          test_prerelease_versions
        end

        def test_version_ranges
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, '^1.0.0')
          refute node_collection.send(:local_dependency?, '~2.3.4')
          refute node_collection.send(:local_dependency?, '>=1.0.0')
        end

        def test_exact_versions
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, '1.0.0')
        end

        def test_special_versions
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, 'latest')
          refute node_collection.send(:local_dependency?, 'next')
          refute node_collection.send(:local_dependency?, 'beta')
        end

        def test_prerelease_versions
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, '1.0.0-alpha.1')
        end

        def test_git_remote_repositories_not_filtered
          # Test that remote git repositories are not filtered
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, 'git+https://github.com/user/repo.git')
          refute node_collection.send(:local_dependency?, 'git+ssh://git@github.com/user/repo.git')
          refute node_collection.send(:local_dependency?, 'git://github.com/user/repo.git')
          refute node_collection.send(:local_dependency?, 'https://github.com/user/repo/archive/master.tar.gz')
        end

        def test_local_dependency_edge_cases
          # Test edge cases
          node_collection = create_node_collection

          refute node_collection.send(:local_dependency?, '')
          refute node_collection.send(:local_dependency?, nil)

          # Test symbols (should be converted to string)
          assert node_collection.send(:local_dependency?, :'file:./local')
          refute node_collection.send(:local_dependency?, :'^1.0.0')
        end
      end
    end
  end
end
