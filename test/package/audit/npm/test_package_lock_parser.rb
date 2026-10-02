require 'test_helper'

require_relative '../../../../lib/package/audit/npm/node_collection'
require_relative '../../../../lib/package/audit/npm/package_lock_parser'
require_relative '../../../../lib/package/audit/npm/vulnerability_finder'

module Package
  module Audit
    module Npm
      class TestPackageLockParser < Minitest::Test
        V3_DIR = File.join(Dir.pwd, 'test/files/npm-lock/v3')
        V1_DIR = File.join(Dir.pwd, 'test/files/npm-lock/v1')

        DEPS = { 'js-tokens' => '^8.0.0', '@scope/widget' => '^1.0.0' }.freeze
        DEV_DEPS = { 'semver' => '^6.3.0' }.freeze

        def test_v3_direct_dependencies_use_top_level_versions
          pkgs = parser(V3_DIR).fetch(DEPS, DEV_DEPS)

          assert_equal({ 'js-tokens' => '8.0.1', '@scope/widget' => '1.2.3', 'semver' => '6.3.0' }, versions(pkgs))
        end

        def test_v3_groups_follow_package_json_sections
          pkgs = parser(V3_DIR).fetch({ 'js-tokens' => '^8.0.0' }, { 'semver' => '^6.3.0' })

          assert_equal [Enum::Group::DEFAULT, Enum::Group::DEV], pkgs.find { |p| p.name == 'js-tokens' }.groups
          assert_equal [Enum::Group::DEV], pkgs.find { |p| p.name == 'semver' }.groups
        end

        def test_v3_all_packages_includes_nested_and_skips_workspace_links
          all = parser(V3_DIR).all_packages

          assert_includes all, ['semver', '5.7.2']
          assert_includes all, ['semver', '6.3.0']
          assert_includes all, ['@scope/widget', '1.2.3']
          assert_empty(all.select { |name, _| name.include?('local-tool') })
        end

        def test_v1_direct_dependencies_and_nested_packages
          lock = parser(V1_DIR)
          pkgs = lock.fetch(DEPS, DEV_DEPS)

          assert_equal({ 'js-tokens' => '8.0.1', '@scope/widget' => '1.2.3', 'semver' => '6.3.0' }, versions(pkgs))
          assert_includes lock.all_packages, ['semver', '5.7.2']
        end

        def test_missing_dependency_raises
          error = assert_raises(NoMatchingPatternError) { parser(V3_DIR).fetch({ 'missing' => '^1.0.0' }, {}) }

          assert_match(/Unable to find "missing"/, error.message)
        end

        def test_node_collection_reads_package_lock_when_yarn_lock_is_absent
          pkgs = NodeCollection.new(V3_DIR, :all).send(:fetch_from_lock_file)

          assert_equal %w[@scope/widget deprecated js-tokens semver], pkgs.map(&:name).sort
        end

        def test_vulnerability_finder_collects_versions_from_package_lock
          implicit = NodeCollection.new(V3_DIR, :all).send(:fetch_from_lock_file)
          versions_by_name = VulnerabilityFinder.new(V3_DIR, implicit).send(:collect_versions_by_name)

          assert_equal %w[5.7.2 6.3.0], versions_by_name['semver'].sort
        end

        private

        def parser(dir)
          PackageLockParser.new(File.join(dir, 'package-lock.json'))
        end

        def versions(pkgs)
          pkgs.to_h { |pkg| [pkg.name, pkg.version] }
        end
      end
    end
  end
end
