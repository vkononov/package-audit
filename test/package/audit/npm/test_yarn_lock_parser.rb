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

        def test_all_packages_together
          pkgs = fetch_all_packages

          assert_equal 5, pkgs.size
          assert_package_versions(pkgs)
        end

        private

        def fetch_all_packages
          deps = {
            'lodash' => '4.17.0',
            'react' => '^17.0.0',
            'express' => '~4.17.0',
            '@types/node' => '18.0.0',
            '@babel/core' => '7.22.0'
          }
          resolutions = {
            'react' => '17.0.2',
            '@babel/core' => '7.22.1'
          }
          @parser.fetch(deps, {}, resolutions)
        end

        def assert_package_versions(pkgs)
          expected_versions = {
            'lodash' => '4.17.0',
            'react' => '17.0.2',
            'express' => '4.17.3',
            '@types/node' => '18.0.0',
            '@babel/core' => '7.22.1'
          }

          expected_versions.each do |name, version|
            assert_package_version(pkgs, name, version)
          end
        end

        def assert_package_version(pkgs, name, version)
          pkg = pkgs.find { |p| p.name == name }

          assert_equal version, pkg.version
        end
      end
    end
  end
end
