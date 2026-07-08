require 'test_helper'

module Package
  module Audit
    class TestGemspec < Minitest::Test
      GEMSPEC_PATH = File.expand_path('../../package-audit.gemspec', __dir__)
      README_PATH = File.expand_path('../../README.md', __dir__)

      def setup
        @spec = Gem::Specification.load(GEMSPEC_PATH)
      end

      def test_that_readme_referenced_images_are_packaged
        local_images = File.read(README_PATH)
                           .scan(/!\[[^\]]*\]\(([^)]+)\)/).flatten
                           .reject { |path| path.start_with?('http://', 'https://') }

        refute_empty local_images, 'Expected the README to reference at least one local image'

        local_images.each do |path|
          assert_includes @spec.files, path,
                          "README references '#{path}' but it is not included in the packaged gem"
        end
      end
    end
  end
end
