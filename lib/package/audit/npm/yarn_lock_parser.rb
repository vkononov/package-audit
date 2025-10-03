require_relative '../enum/group'

module Package
  module Audit
    module Npm
      class YarnLockParser
        def initialize(yarn_lock_path)
          @yarn_lock_file = File.read(yarn_lock_path)
          @yarn_lock_path = yarn_lock_path
        end

        def fetch(default_deps, dev_deps, resolutions = {})
          default_deps.merge(dev_deps).map do |dep_name, expected_version|
            process_package(dep_name, expected_version, dev_deps, resolutions)
          end
        end

        private

        def process_package(dep_name, expected_version, dev_deps, resolutions)
          version_to_check = get_version_to_check(dep_name, expected_version, resolutions)
          pkg_block = fetch_package_block(dep_name, version_to_check)
          version = fetch_package_version(dep_name, pkg_block)
          create_package(dep_name, version, dev_deps)
        end

        def get_version_to_check(dep_name, expected_version, resolutions)
          version_to_check = resolutions[dep_name] || expected_version
          return version_to_check unless version_to_check.start_with?('patch:')

          patch_version = version_to_check.match(/patch:.*?@npm%3A([\d.-]+)#/)&.captures&.[](0)
          patch_version || version_to_check
        end

        def create_package(dep_name, version, dev_deps)
          pks = Package.new(dep_name.to_s, version, 'node')
          pks.update groups: package_groups(dep_name, dev_deps)
          pks
        end

        def package_groups(dep_name, dev_deps)
          if dev_deps.key?(dep_name)
            [Enum::Group::DEV]
          else
            [Enum::Group::DEFAULT, Enum::Group::DEV]
          end
        end

        def fetch_package_block(dep_name, expected_version)
          blocks = find_package_blocks(dep_name)
          raise NoMatchingPatternError, "Unable to find \"#{dep_name}\" in #{@yarn_lock_path}" if blocks.empty?

          find_matching_block(blocks, dep_name, expected_version)
        end

        def find_package_blocks(dep_name)
          block_pattern = build_block_pattern(dep_name)
          @yarn_lock_file.scan(block_pattern)
        end

        def build_block_pattern(dep_name)
          /
            ^["']?                                # Start of line with optional quote
            (?:[^"\n]+,\s*)*                     # Any previous entries in a comma-separated list
            (?:patch:)?                          # Optional patch prefix
            #{Regexp.escape(dep_name)}@[^:\n]+   # Our package name and version
            (?:[^"\n]*,\s*[^"\n]+)*             # Any following entries
            ["']?:.*?                            # End quote and colon, followed by the rest
            (?:resolution:.*?)?                  # Optional resolution field
            (?=\n["']|\n\s*\n|\z)               # Until next entry or end of file
          /mx
        end

        def find_matching_block(blocks, dep_name, expected_version)
          version_pattern = build_version_pattern(dep_name, expected_version)
          blocks.find { |block| block.match?(version_pattern) } || blocks.first
        end

        def build_version_pattern(dep_name, expected_version)
          /
            (?:patch:)?#{Regexp.escape(dep_name)}@
            (?:npm:)?#{Regexp.escape(expected_version)}["']?(?:,|:)
          /x
        end

        def fetch_package_version(dep_name, pkg_block)
          # Try different version formats:
          # 1. version: "1.2.3"    - quoted version
          # 2. version: 1.2.3      - unquoted version
          # 3. "pkg@1.2.3":        - version in package spec
          # 4. "pkg@npm:1.2.3":    - version with npm prefix
          # Try to find version in this order:
          # 1. resolution field (for overrides)
          # 2. version field (both quoted and unquoted)
          # 3. package spec
          version = extract_version_from_block(dep_name, pkg_block)

          if version.nil?
            raise NoMatchingPatternError,
                  "Unable to find the version of \"#{dep_name}\" in #{@yarn_lock_path}"
          end

          version || '0.0.0.0'
        end

        def extract_version_from_block(dep_name, pkg_block)
          find_resolution_version(dep_name, pkg_block) ||
            find_version_field(pkg_block) ||
            find_spec_version(dep_name, pkg_block)
        end

        def find_resolution_version(dep_name, pkg_block)
          pattern = /
            resolution:.*?["']#{Regexp.escape(dep_name)}@
            (?:npm:)?(?:patch:#{Regexp.escape(dep_name)}@npm%3A)?
            ([\d.-]+(?:-(?:beta|rc|dev)\.\d+(?:\.\d+)?)?)
            (?:&hash=[a-f0-9]+)?["']
          /x
          pkg_block.match(pattern)&.captures&.[](0)
        end

        def find_version_field(pkg_block)
          pattern = /version["']?\s*["']?([\d.-]+(?:-(?:beta|rc|dev)\.\d+(?:\.\d+)?)?)(?:&hash=[a-f0-9]+)?["']?(?:\s|$)/
          pkg_block.match(pattern)&.captures&.[](0)
        end

        def find_spec_version(dep_name, pkg_block)
          pattern = %r{^.*?#{Regexp.escape(dep_name)}@(?:npm:|https://[^#]+#)?(?:patch:#{Regexp.escape(dep_name)}@npm%3A)?(?:v)?([\d.-]+(?:-(?:beta|rc|dev)\.\d+(?:\.\d+)?)?)(?:&hash=[a-f0-9]+)?["']?(?:,|\s*:)}m
          pkg_block.match(pattern)&.captures&.[](0)
        end

        def regex_pattern_for_package(dep_name, _version)
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
          # Look for any entry that starts with our package name and includes the version
          # We match the entire block and let fetch_package_version handle version extraction
          # The pattern matches:
          # 1. Package name at start of line or after quote
          # 2. Everything up to the next double newline or end of file
          # 3. Handles both compact and expanded formats with dependencies
          # Match both old and new yarn.lock formats:
          # Old: pkg@^1.0.0:
          # New: "pkg@^1.0.0":
          # The pattern matches the entire block including any indented lines
          # We look for:
          # 1. Start of line
          # 2. Optional quote
          # 3. Package name
          # 4. @ symbol
          # 5. Version spec (anything up to : or ")
          # 6. Optional quote and colon
          # 7. Rest of the block until next entry or end of file
          # The pattern needs to match:
          # 1. Basic format: pkg@^1.0.0:
          # 2. Quoted format: "pkg@^1.0.0":
          # 3. Multiple specs: "pkg@1.0.0", "pkg@npm:1.0.0":
          # 4. Scoped packages: "@scope/pkg@1.0.0":
          # Match any of:
          # 1. Basic: pkg@^1.0.0:
          # 2. Quoted: "pkg@^1.0.0":
          # 3. Multiple: "pkg@1.0.0", "pkg@npm:1.0.0":
          # 4. Scoped: "@scope/pkg@1.0.0":
          /^(?:["']?#{escaped_name}@[^,\n:"]+(?:,\s*["']#{escaped_name}@[^,\n:"]+)*["']?:.*?)(?=\n["']|\n\s*\n|\z)/m
        end
      end
    end
  end
end
