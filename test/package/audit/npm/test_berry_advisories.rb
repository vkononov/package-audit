require 'test_helper'
require 'tmpdir'
require_relative '../../../../lib/package/audit/npm/vulnerability_finder'

module Package
  module Audit
    module Npm
      class TestBerryAdvisories < Minitest::Test
        def test_collects_transitive_versions_from_classic_and_berry_locks # rubocop:disable Metrics/MethodLength
          ["transitive@^1:\n  version \"1.2.3\"\n", "\"transitive@npm:^1\":\n  version: 1.2.3\n"].each do |lock|
            Dir.mktmpdir do |dir|
              File.write(File.join(dir, 'yarn.lock'), lock)
              finder = VulnerabilityFinder.new(dir, [])
              request = lambda do |_uri, body|
                assert_equal({ 'transitive' => ['1.2.3'] }, JSON.parse(body))
                response = Net::HTTPOK.new('1.1', '200', 'OK')
                response.define_singleton_method(:body) do
                  '{"transitive":[{"vulnerable_versions":"<2.0.0","severity":"high"}]}'
                end
                response
              end

              finder.stub(:make_request, request) do
                assert_equal ['transitive@1.2.3'], finder.run.map(&:full_name)
              end
            end
          end
        end
      end
    end
  end
end
