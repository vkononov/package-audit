require 'test_helper'

require_relative '../../../../lib/package/audit/ruby/bundler_specs'

module Package
  module Audit
    module Ruby
      class TestBundlerSpecs < Minitest::Test # rubocop:disable Metrics/ClassLength
        def test_local_dependency_detection_with_path_source
          # Mock a spec with path source
          spec = Minitest::Mock.new
          path_source = Minitest::Mock.new

          spec.expect(:source, path_source)
          path_source.expect(:is_a?, true, [Bundler::Source::Path])

          assert BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          path_source.verify
        end

        def test_local_dependency_detection_with_local_git_source
          # Mock a spec with local git source
          spec = Minitest::Mock.new
          git_source = Minitest::Mock.new

          spec.expect(:source, git_source)
          git_source.expect(:is_a?, false, [Bundler::Source::Path])
          git_source.expect(:is_a?, true, [Bundler::Source::Git])
          git_source.expect(:uri, 'file:./local-git-repo')

          assert BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          git_source.verify
        end

        def test_local_dependency_detection_with_relative_git_source
          # Mock a spec with relative path git source
          spec = Minitest::Mock.new
          git_source = Minitest::Mock.new

          spec.expect(:source, git_source)
          git_source.expect(:is_a?, false, [Bundler::Source::Path])
          git_source.expect(:is_a?, true, [Bundler::Source::Git])
          git_source.expect(:uri, '../shared-git-repo')

          assert BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          git_source.verify
        end

        def test_local_dependency_detection_with_current_dir_git_source
          # Mock a spec with current directory git source
          spec = Minitest::Mock.new
          git_source = Minitest::Mock.new

          spec.expect(:source, git_source)
          git_source.expect(:is_a?, false, [Bundler::Source::Path])
          git_source.expect(:is_a?, true, [Bundler::Source::Git])
          git_source.expect(:uri, './local-git-repo')

          assert BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          git_source.verify
        end

        def test_normal_dependency_detection_with_rubygems_source
          # Mock a spec with normal rubygems source
          spec = Minitest::Mock.new
          rubygems_source = Minitest::Mock.new

          spec.expect(:source, rubygems_source)
          rubygems_source.expect(:is_a?, false, [Bundler::Source::Path])
          rubygems_source.expect(:is_a?, false, [Bundler::Source::Git])

          refute BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          rubygems_source.verify
        end

        def test_normal_dependency_detection_with_remote_git_source
          # Mock a spec with remote git source
          spec = Minitest::Mock.new
          git_source = Minitest::Mock.new

          spec.expect(:source, git_source)
          git_source.expect(:is_a?, false, [Bundler::Source::Path])
          git_source.expect(:is_a?, true, [Bundler::Source::Git])
          git_source.expect(:uri, 'https://github.com/user/repo.git')

          refute BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          git_source.verify
        end

        def test_normal_dependency_detection_with_ssh_git_source
          # Mock a spec with SSH git source
          spec = Minitest::Mock.new
          git_source = Minitest::Mock.new

          spec.expect(:source, git_source)
          git_source.expect(:is_a?, false, [Bundler::Source::Path])
          git_source.expect(:is_a?, true, [Bundler::Source::Git])
          git_source.expect(:uri, 'git@github.com:user/repo.git')

          refute BundlerSpecs.send(:local_dependency?, spec)

          spec.verify
          git_source.verify
        end

        def test_filter_local_dependencies_with_mixed_sources
          # Create simple test objects instead of mocks for array operations
          path_spec = TestSpec.new(:path)
          git_local_spec = TestSpec.new(:git_local)
          git_remote_spec = TestSpec.new(:git_remote)
          rubygems_spec = TestSpec.new(:rubygems)

          specs = [path_spec, git_local_spec, git_remote_spec, rubygems_spec]

          filtered = BundlerSpecs.send(:filter_local_dependencies, specs)

          # Should only keep remote git and rubygems specs
          assert_equal 2, filtered.size
          assert_includes filtered, git_remote_spec
          assert_includes filtered, rubygems_spec

          # Should filter out local specs
          refute_includes filtered, path_spec
          refute_includes filtered, git_local_spec
        end

        def test_filter_local_dependencies_with_all_local
          # Create simple test objects that are all local
          path_spec = TestSpec.new(:path)
          git_local_spec = TestSpec.new(:git_local)

          specs = [path_spec, git_local_spec]

          filtered = BundlerSpecs.send(:filter_local_dependencies, specs)

          # Should filter out all specs
          assert_equal 0, filtered.size
        end

        def test_filter_local_dependencies_with_all_remote
          # Create simple test objects that are all remote
          git_remote_spec = TestSpec.new(:git_remote)
          rubygems_spec = TestSpec.new(:rubygems)

          specs = [git_remote_spec, rubygems_spec]

          filtered = BundlerSpecs.send(:filter_local_dependencies, specs)

          # Should keep all specs
          assert_equal 2, filtered.size
          assert_includes filtered, git_remote_spec
          assert_includes filtered, rubygems_spec
        end

        def test_filter_local_dependencies_with_empty_array
          filtered = BundlerSpecs.send(:filter_local_dependencies, [])

          assert_equal 0, filtered.size
        end

        # Simple test spec class to avoid mock issues with array operations
        class TestSpec
          def initialize(source_type)
            @source_type = source_type
          end

          def source
            case @source_type
            when :path
              TestPathSource.new
            when :git_local
              TestGitSource.new('file:./local-git-repo')
            when :git_remote
              TestGitSource.new('https://github.com/user/repo.git')
            when :rubygems
              TestRubygemsSource.new
            end
          end
        end

        class TestPathSource
          def is_a?(klass)
            klass == Bundler::Source::Path
          end
        end

        class TestGitSource
          def initialize(uri)
            @uri = uri
          end

          def is_a?(klass)
            klass == Bundler::Source::Git
          end

          attr_reader :uri
        end

        class TestRubygemsSource
          def is_a?(_klass)
            false
          end
        end
      end
    end
  end
end
