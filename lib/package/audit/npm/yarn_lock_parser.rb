require_relative '../enum/group'

module Package
  module Audit
    module Npm
      class YarnLockParser
        def initialize(yarn_lock_path)
          @yarn_lock_file = File.read(yarn_lock_path)
          @yarn_lock_path = yarn_lock_path
        end

        def fetch(default_deps, dev_deps, resolutions = {}) # rubocop:disable Metrics/MethodLength
          pkgs = []
          default_deps.merge(dev_deps).each do |dep_name, expected_version|
            # Check if there's a resolution override for this package
            version_to_check = resolutions[dep_name] || expected_version
            
            pkg_block = fetch_package_block(dep_name, version_to_check)
            version = fetch_package_version(dep_name, pkg_block)
            pks = Package.new(dep_name.to_s, version, 'node')
            pks.update groups: if dev_deps.key?(dep_name)
                                 [Enum::Group::DEV]
                               else
                                 [Enum::Group::DEFAULT, Enum::Group::DEV]
                               end
            pkgs << pks
          end
          pkgs
        end

        private

        def fetch_package_block(dep_name, expected_version)
          regex = regex_pattern_for_package(dep_name, expected_version)
          blocks = @yarn_lock_file.match(regex)
          if blocks.nil? || blocks[0].nil?
            raise NoMatchingPatternError, "Unable to find \"#{dep_name}\" in #{@yarn_lock_path}"
          end

          blocks[0] || ''
        end

        def fetch_package_version(dep_name, pkg_block)
          # Try different version formats:
          # 1. version: "1.2.3"    - quoted version
          # 2. version: 1.2.3      - unquoted version
          # 3. "pkg@1.2.3":        - version in package spec
          # 4. "pkg@npm:1.2.3":    - version with npm prefix
          version = pkg_block.match(/version["']?: ["']?(.*?)["']?(?:\s|$)/)&.captures&.[](0) ||
                   pkg_block.match(/#{Regexp.escape(dep_name)}@(?:npm:)?([\d.]+)[":]/)&.captures&.[](0)
          
          if version.nil?
            raise NoMatchingPatternError,
                  "Unable to find the version of \"#{dep_name}\" in #{@yarn_lock_path}"
          end

          version || '0.0.0.0'
        end

        def regex_pattern_for_package(dep_name, version)
          # assume the package name is prefixed by a space, a quote or be the first thing on the line
          # there can be multiple comma-separated versions on the same line with or without quotes
          # Here are some examples of strings that would be matched:
          # - aria-query@^5.0.0:
          # - lodash@^4.17.15, lodash@^4.17.20:
          # - "@adobe/css-tools@^4.0.1":
          # - "@babel/runtime@^7.23.1", "@babel/runtime@^7.9.2":
          # For resolutions (exact versions):
          # - "@apollo/client@3.12.5":
          # For both regular dependencies and resolutions
          # The package might appear in different formats:
          # 1. As a dependency spec: "@apollo/client@^3.14.0"
          # 2. As a resolved version: "@apollo/client@3.12.5"
          # 3. As part of a multi-version spec: "@apollo/client@^3.14.0, @apollo/client@^3.12.5"
          # 4. With npm prefix: "@apollo/client@npm:3.12.5"
          # 5. In resolution field: "resolution: \"@apollo/client@npm:3.12.5\""
          escaped_name = Regexp.escape(dep_name)
          escaped_version = Regexp.escape(version)
          /(?:^|[ "])#{escaped_name}@(?:npm:)?(?:#{escaped_version}|[^\s,:"]*#{escaped_version}[^\s,:"]*)[,"]?:.*?(?:\n\n|\z)|resolution: "#{escaped_name}@(?:npm:)?#{escaped_version}"/m
        end
      end
    end
  end
end
