require 'json'

require_relative '../enum/group'
require_relative '../models/package'

# Ruby 2.7 added this. A missing lockfile entry raises it, same as the yarn parser.
Object.const_set(:NoMatchingPatternError, Class.new(StandardError)) unless defined?(NoMatchingPatternError)

module Package
  module Audit
    module Npm
      # Reads package-lock.json (lockfileVersion 1, 2 and 3) and resolves the
      # installed version of each direct dependency.
      class PackageLockParser
        NODE_MODULES = 'node_modules/'

        def initialize(package_lock_path)
          @package_lock_path = package_lock_path
          @lock = JSON.parse(File.read(package_lock_path))
        end

        def fetch(default_deps, dev_deps, _resolutions = {})
          default_deps.merge(dev_deps).map do |dep_name, _expected_version|
            version = direct_version(dep_name)
            raise NoMatchingPatternError, "Unable to find \"#{dep_name}\" in #{@package_lock_path}" if version.nil?

            pkg = Package.new(dep_name.to_s, version, 'node')
            pkg.update groups: package_groups(dep_name, dev_deps)
            pkg
          end
        end

        # Every installed package, including transitive ones, as [name, version] pairs.
        # Entries outside node_modules are workspace sources, not registry packages.
        def all_packages
          if @lock.key?('packages')
            @lock['packages'].map do |path, entry|
              next if entry['version'].nil? || !path.include?(NODE_MODULES)

              [name_from_path(path), entry['version']]
            end.compact
          else
            walk_v1(@lock['dependencies'] || {})
          end
        end

        private

        def direct_version(dep_name)
          if @lock.key?('packages')
            @lock.dig('packages', "#{NODE_MODULES}#{dep_name}", 'version')
          else
            @lock.dig('dependencies', dep_name, 'version')
          end
        end

        def package_groups(dep_name, dev_deps)
          if dev_deps.key?(dep_name)
            [Enum::Group::DEV]
          else
            [Enum::Group::DEFAULT, Enum::Group::DEV]
          end
        end

        # "node_modules/a/node_modules/@scope/b" => "@scope/b"
        def name_from_path(path)
          path.split(NODE_MODULES).last
        end

        def walk_v1(dependencies, packages = [])
          dependencies.each do |name, entry|
            packages << [name, entry['version']] unless entry['version'].nil?
            walk_v1(entry['dependencies'] || {}, packages)
          end
          packages
        end
      end
    end
  end
end
