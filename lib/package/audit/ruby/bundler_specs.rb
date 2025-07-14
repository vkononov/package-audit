require_relative '../models/package'
require_relative 'gem_meta_data'
require_relative 'vulnerability_finder'

require 'bundler'

module Package
  module Audit
    module Ruby
      class BundlerSpecs
        def self.all(dir)
          specs = Bundler.with_unbundled_env do
            ENV['BUNDLE_GEMFILE'] = "#{dir}/Gemfile"
            Bundler.ui.silence { Bundler.definition.resolve }
          end
          filter_local_dependencies(specs)
        end

        def self.gemfile(dir)
          current_dependencies = Bundler.with_unbundled_env do
            ENV['BUNDLE_GEMFILE'] = "#{dir}/Gemfile"
            Bundler.ui.level = 'error'
            Bundler.reset!
            Bundler.ui.silence do
              Bundler.load.dependencies.to_h { |dep| [dep.name, dep] }
            end
          end

          gemfile_specs, = all(dir).partition do |spec|
            current_dependencies.key? spec.name
          end
          gemfile_specs
        end

        def self.filter_local_dependencies(specs)
          specs.reject { |spec| local_dependency?(spec) }
        end

        def self.local_dependency?(spec)
          # Check if the gem has a local source (path or git with local path)
          source = spec.source
          return true if source.is_a?(Bundler::Source::Path)
          return true if source.is_a?(Bundler::Source::Git) && source.uri.start_with?('file:', './', '../')

          false
        end
      end
    end
  end
end
