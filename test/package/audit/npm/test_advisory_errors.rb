require 'test_helper'
require_relative '../../../../lib/package/audit/npm/vulnerability_finder'

module Package
  module Audit
    module Npm
      class TestAdvisoryErrors < Minitest::Test
        def test_request_failure_is_not_a_successful_empty_audit
          package = Package.new('example', '1.0.0', 'node')
          finder = VulnerabilityFinder.new('/nonexistent', [package])
          failure = ->(*) { raise IOError, 'simulated outage' }

          finder.stub(:make_request, failure) do
            assert_raises(IOError) { finder.run }
          end
        end

        def test_http_failure_and_invalid_response_shape_are_not_clean_audits
          package = Package.new('example', '1.0.0', 'node')
          [Net::HTTPServiceUnavailable.new('1.1', '503', 'Unavailable'),
           Net::HTTPOK.new('1.1', '200', 'OK')].each do |response|
            response.define_singleton_method(:body) { '[]' }
            finder = VulnerabilityFinder.new('/nonexistent', [package])

            finder.stub(:make_request, response) do
              assert_raises(RuntimeError) { finder.run }
            end
          end
        end
      end
    end
  end
end
