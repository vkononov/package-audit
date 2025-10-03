require 'json'
require 'net/http'
require 'socket'

module Package
  module Audit
    module Npm
      class NpmMetaData
        REGISTRY_URL = 'https://registry.npmjs.org'
        BATCH_SIZE = 10 # Process 10 packages at a time
        MAX_RETRIES = 3 # Maximum number of retries per request
        INITIAL_RETRY_DELAY = 1 # Initial retry delay in seconds
        TIMEOUT = 10 # Timeout in seconds

        def initialize(packages)
          @packages = packages
        end

        def fetch # rubocop:disable Metrics/MethodLength
          network_errors = []

          @packages.each_slice(BATCH_SIZE) do |batch|
            threads = batch.map do |package|
              Thread.new do
                fetch_package_metadata(package, network_errors)
              end
            end

            threads.each(&:join)
            sleep(0.1) # Small delay between batches to avoid overwhelming the server
          end

          unless network_errors.empty?
            warn "Warning: #{network_errors.size} network error(s) occurred while fetching package metadata."
            warn 'Some packages may not show complete version information.'
          end

          @packages
        end

        private

        def fetch_package_metadata(package, network_errors, retry_count = 0)
          response = make_request_with_retry(package.name, retry_count)
          return if response.nil?

          json_package = JSON.parse(response.body, symbolize_names: true)
          update_meta_data(package, json_package)
        rescue StandardError => e
          handle_error(package, e, network_errors)
        end

        def make_request_with_retry(package_name, retry_count)
          response = make_request(package_name)
          raise "Unable to fetch meta data for #{package_name} from #{REGISTRY_URL} (#{response.class})" unless
            response.is_a?(Net::HTTPSuccess)

          response
        rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return nil if retry_count >= MAX_RETRIES

          retry_after_delay(retry_count)
          retry_count += 1
          retry
        end

        def handle_error(package, error, network_errors)
          warn "Warning: Error while fetching metadata for #{package.name}: #{error.message}"
          network_errors << error
        end

        def make_request(package_name)
          uri = URI(REGISTRY_URL)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.read_timeout = TIMEOUT
          http.open_timeout = TIMEOUT

          path = "/#{package_name}"
          http.get(path)
        end

        def retry_after_delay(retry_count)
          delay = INITIAL_RETRY_DELAY * (2**retry_count) # Exponential backoff
          sleep(delay)
        end

        def update_meta_data(package, json_data)
          latest_version = json_data[:'dist-tags'][:latest]
          version_date = json_data[:time][package.version.to_sym]
          latest_version_date = json_data[:time][latest_version.to_sym]
          package.update version_date: Time.parse(version_date).strftime('%Y-%m-%d'),
                         latest_version: latest_version,
                         latest_version_date: Time.parse(latest_version_date).strftime('%Y-%m-%d')
        end
      end
    end
  end
end
