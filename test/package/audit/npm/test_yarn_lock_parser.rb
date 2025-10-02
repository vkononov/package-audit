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
          deps = { "lodash" => "4.17.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "4.17.0", pkgs.find { |p| p.name == "lodash" }.version
        end

        def test_caret_version_with_resolution
          deps = { "react" => "^17.0.0" }
          resolutions = { "react" => "17.0.2" }
          pkgs = @parser.fetch(deps, {}, resolutions)
          assert_equal "17.0.2", pkgs.find { |p| p.name == "react" }.version
        end

        def test_tilde_version_with_colon_syntax
          deps = { "express" => "~4.17.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "4.17.3", pkgs.find { |p| p.name == "express" }.version
        end

        def test_scoped_package_with_npm_prefix
          deps = { "@types/node" => "18.0.0" }
          pkgs = @parser.fetch(deps, {})
          assert_equal "18.0.0", pkgs.find { |p| p.name == "@types/node" }.version
        end

        def test_package_with_resolution_field
          deps = { "@babel/core" => "7.22.0" }
          resolutions = { "@babel/core" => "7.22.1" }
          pkgs = @parser.fetch(deps, {}, resolutions)
          assert_equal "7.22.1", pkgs.find { |p| p.name == "@babel/core" }.version
        end

        def test_all_packages_together
          deps = {
            "lodash" => "4.17.0",
            "react" => "^17.0.0",
            "express" => "~4.17.0",
            "@types/node" => "18.0.0",
            "@babel/core" => "7.22.0"
          }
          resolutions = {
            "react" => "17.0.2",
            "@babel/core" => "7.22.1"
          }
          pkgs = @parser.fetch(deps, {}, resolutions)

          assert_equal 5, pkgs.size
          assert_equal "4.17.0", pkgs.find { |p| p.name == "lodash" }.version
          assert_equal "17.0.2", pkgs.find { |p| p.name == "react" }.version
          assert_equal "4.17.3", pkgs.find { |p| p.name == "express" }.version
          assert_equal "18.0.0", pkgs.find { |p| p.name == "@types/node" }.version
          assert_equal "7.22.1", pkgs.find { |p| p.name == "@babel/core" }.version
        end
      end
    end
  end
end