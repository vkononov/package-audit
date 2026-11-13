require 'test_helper'
require 'rubygems/spec_fetcher'
require_relative '../../../../lib/package/audit/ruby/gem_meta_data'

module Package
  module Audit
    module Ruby
      class TestGemMetaData < Minitest::Test
        def test_missing_registry_metadata_preserves_known_vulnerability
          package = Package.new('yanked-example', '1.0.0', 'ruby', vulnerabilities: ['high'])
          fetcher = Object.new
          fetcher.define_singleton_method(:spec_for_dependency) { |_dependency| [[], []] }
          metadata = GemMetaData.new('.', [package])
          definition = Struct.new(:groups).new([])
          Gem::SpecFetcher.stub(:fetcher, fetcher) do
            metadata.stub(:build_bundler_definition, definition) do
              assert_equal [package], metadata.fetch
              assert_predicate package, :vulnerable?
            end
          end
        end
      end
    end
  end
end
