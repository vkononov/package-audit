require 'test_helper'

require_relative '../../../../lib/package/audit/npm/yarn_lock_parser'

module Package
  module Audit
    module Npm
      class TestYarnLockParserVersionPatterns < Minitest::Test
        def setup
          @test_dir = File.join(Dir.pwd, 'test/files/yarn/version-patterns')
        end

        def test_standard_version_format
          parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
          deps = { 'lodash' => '4.17.0' }
          pkgs = parser.fetch(deps, {})

          assert_equal '4.17.0', pkgs.find { |p| p.name == 'lodash' }.version
        end

        def test_caret_version_with_resolution
          parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
          deps = { 'react' => '^17.0.0' }
          resolutions = { 'react' => '17.0.2' }
          pkgs = parser.fetch(deps, {}, resolutions)

          assert_equal '17.0.2', pkgs.find { |p| p.name == 'react' }.version
        end

        def test_tilde_version_with_colon_syntax
          parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
          deps = { 'express' => '~4.17.0' }
          pkgs = parser.fetch(deps, {})

          assert_equal '4.17.3', pkgs.find { |p| p.name == 'express' }.version
        end

        def test_scoped_package_with_npm_prefix
          parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
          deps = { '@types/node' => '18.0.0' }
          pkgs = parser.fetch(deps, {})

          assert_equal '18.0.0', pkgs.find { |p| p.name == '@types/node' }.version
        end

        def test_package_with_resolution_field
          parser = YarnLockParser.new(File.join(@test_dir, 'yarn.lock'))
          deps = { '@babel/core' => '7.22.0' }
          resolutions = { '@babel/core' => '7.22.1' }
          pkgs = parser.fetch(deps, {}, resolutions)

          assert_equal '7.22.1', pkgs.find { |p| p.name == '@babel/core' }.version
        end

        def test_git_url_package
          parser = YarnLockParser.new(File.join(@test_dir, 'git-url.lock'))
          deps = { '@fullscript/graphql-codegen-object-types' => 'https://github.com/Fullscript/graphql-codegen-object-types.git#2.0.0' }
          pkgs = parser.fetch(deps, {})

          assert_equal '2.0.0', pkgs.find { |p| p.name == '@fullscript/graphql-codegen-object-types' }.version
        end

        def test_hyphenated_version
          parser = YarnLockParser.new(File.join(@test_dir, 'hyphenated.lock'))
          deps = { '@rails/ujs' => '6.1.4-1' }
          pkgs = parser.fetch(deps, {})

          assert_equal '6.1.4-1', pkgs.find { |p| p.name == '@rails/ujs' }.version
        end

        def test_beta_version
          parser = YarnLockParser.new(File.join(@test_dir, 'beta.lock'))
          deps = { 'body-scroll-lock' => '4.0.0-beta.0' }
          pkgs = parser.fetch(deps, {})

          assert_equal '4.0.0-beta.0', pkgs.find { |p| p.name == 'body-scroll-lock' }.version
        end

        def test_rc_version
          parser = YarnLockParser.new(File.join(@test_dir, 'rc.lock'))
          deps = { 'cheerio' => '1.0.0-rc.12' }
          pkgs = parser.fetch(deps, {})

          assert_equal '1.0.0-rc.12', pkgs.find { |p| p.name == 'cheerio' }.version
        end

        def test_git_url_with_v_prefix
          parser = YarnLockParser.new(File.join(@test_dir, 'git-url-with-v.lock'))
          deps = { 'aviary-tokens' => 'https://github.com/Fullscript/aviary-tokens.git#v1.3.1' }
          pkgs = parser.fetch(deps, {})

          assert_equal '1.3.1', pkgs.find { |p| p.name == 'aviary-tokens' }.version
        end

        def test_patch_version
          parser = YarnLockParser.new(File.join(@test_dir, 'patch.lock'))
          deps = { 'code-complexity' => '4.4.4' }
          pkgs = parser.fetch(deps, {})

          assert_equal '4.4.4', pkgs.find { |p| p.name == 'code-complexity' }.version
        end
      end
    end
  end
end
