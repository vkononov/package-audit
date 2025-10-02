require 'test_helper'

require_relative '../../../../lib/package/audit/npm/yarn_lock_parser'

module Package
  module Audit
    module Npm
      class TestYarnLockParser < Minitest::Test
        def setup
          @test_dir = File.join(Dir.pwd, 'test/files/yarn/version-patterns')
          @parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
        end

        def test_standard_version_format
          deps = { "pkg1" => "1.0.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "1.0.0", pkgs.find { |p| p.name == "pkg1" }.version
        end

        def test_caret_version_with_resolution
          deps = { "pkg2" => "^2.0.0" }
          resolutions = { "pkg2" => "2.0.0" }
          pkgs = @parser.fetch(deps, {}, resolutions)
          assert_equal "2.0.0", pkgs.find { |p| p.name == "pkg2" }.version
        end

        def test_tilde_version_with_colon_syntax
          deps = { "pkg3" => "~3.0.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "3.0.0", pkgs.find { |p| p.name == "pkg3" }.version
        end

        def test_scoped_package_with_npm_prefix
          deps = { "@scoped/pkg" => "4.0.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "4.0.0", pkgs.find { |p| p.name == "@scoped/pkg" }.version
        end

        def test_package_with_resolution_field
          deps = { "pkg-with-resolution" => "5.0.0" }
          resolutions = { "pkg-with-resolution" => "5.1.0" }
          pkgs = @parser.fetch(deps, {}, resolutions)
          assert_equal "5.1.0", pkgs.find { |p| p.name == "pkg-with-resolution" }.version
        end

        def test_all_packages_together
          deps = {
            "pkg1" => "1.0.0",
            "pkg2" => "^2.0.0",
            "pkg3" => "~3.0.0",
            "@scoped/pkg" => "4.0.0",
            "pkg-with-resolution" => "5.0.0"
          }
          resolutions = {
            "pkg2" => "2.0.0",
            "pkg-with-resolution" => "5.1.0"
          }
          pkgs = @parser.fetch(deps, {}, resolutions)

          assert_equal 5, pkgs.size
          assert_equal "1.0.0", pkgs.find { |p| p.name == "pkg1" }.version
          assert_equal "2.0.0", pkgs.find { |p| p.name == "pkg2" }.version
          assert_equal "3.0.0", pkgs.find { |p| p.name == "pkg3" }.version
          assert_equal "4.0.0", pkgs.find { |p| p.name == "@scoped/pkg" }.version
          assert_equal "5.1.0", pkgs.find { |p| p.name == "pkg-with-resolution" }.version
        end
      end
    end
  end
end