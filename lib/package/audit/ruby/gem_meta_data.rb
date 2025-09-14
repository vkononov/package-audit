require_relative '../models/package'

module Package
  module Audit
    module Ruby
      class GemMetaData # rubocop:disable Metrics/ClassLength
        # API and timeout constants
        RUBYGEMS_API_BASE = 'https://rubygems.org/api/v1/versions'
        HTTP_READ_TIMEOUT = 10
        HTTP_OPEN_TIMEOUT = 5
        PLACEHOLDER_DATE_THRESHOLD = 1980
        DEFAULT_DATE_FORMAT = '%Y-%m-%d'
        EPOCH_TIME = Time.new(0)
        INITIAL_VERSION = Gem::Version.new('0.0.0.0')

        def initialize(dir, pkgs)
          @dir = dir
          @pkgs = pkgs
          @gem_hash = {}
        end

        def fetch
          find_rubygems_metadata
          assign_groups
          @gem_hash.values
        end

        private

        def find_rubygems_metadata
          # Performance-optimized approach:
          # 1. Use fast local SpecFetcher for version numbers and dates
          # 2. Only make HTTP API calls for gems with placeholder dates (1980-01-02)
          # 3. This avoids network calls for gems with proper local date metadata
          fetcher = Gem::SpecFetcher.fetcher
          gems_needing_api_lookup = []

          @pkgs.each do |pkg|
            result = process_package_metadata(pkg, fetcher)
            next unless result

            if result[:needs_api_lookup]
              gems_needing_api_lookup << result[:gem_data]
            else
              update_package_with_local_dates(pkg, result[:metadata])
            end
          end

          # Batch API lookups only for gems with placeholder dates
          process_api_lookups(gems_needing_api_lookup) unless gems_needing_api_lookup.empty?
        end

        def needs_api_lookup?(date)
          return true if date.nil?

          date.year <= PLACEHOLDER_DATE_THRESHOLD
        end

        def process_package_metadata(pkg, fetcher)
          gem_dependency = Gem::Dependency.new pkg.name, ">= #{pkg.version}"
          remote_dependencies, = fetcher.spec_for_dependency gem_dependency
          return nil unless remote_dependencies.any?

          metadata = extract_local_metadata(pkg, remote_dependencies)
          needs_lookup = needs_api_lookup?(metadata[:local_version_date]) ||
                         needs_api_lookup?(metadata[:latest_version_date])

          {
            needs_api_lookup: needs_lookup,
            metadata: metadata,
            gem_data: needs_lookup ? build_gem_data(pkg, metadata) : nil
          }
        end

        def extract_local_metadata(pkg, remote_dependencies)
          metadata = initialize_metadata_defaults(pkg)

          remote_dependencies.each do |remote_spec, _|
            update_version_info(metadata, remote_spec)
          end

          metadata
        end

        def initialize_metadata_defaults(pkg)
          {
            local_version_date: EPOCH_TIME,
            latest_version_date: EPOCH_TIME,
            local_version: Gem::Version.new(pkg.version),
            latest_version: INITIAL_VERSION
          }
        end

        def update_version_info(metadata, remote_spec)
          metadata[:latest_version] = remote_spec.version if metadata[:latest_version] < remote_spec.version

          metadata[:latest_version_date] = remote_spec.date if metadata[:latest_version_date] < remote_spec.date

          return unless metadata[:local_version] == remote_spec.version

          metadata[:local_version_date] = remote_spec.date
        end

        def build_gem_data(pkg, metadata)
          {
            pkg: pkg,
            latest_version: metadata[:latest_version].to_s,
            local_version_date: metadata[:local_version_date],
            latest_version_date: metadata[:latest_version_date]
          }
        end

        def update_package_with_local_dates(pkg, metadata)
          store_package(pkg)
          pkg.update(
            latest_version: metadata[:latest_version].to_s,
            version_date: format_time(metadata[:local_version_date]),
            latest_version_date: format_time(metadata[:latest_version_date])
          )
        end

        def store_package(pkg)
          @gem_hash[pkg.name] = pkg
        end

        def format_time(time)
          time.strftime(DEFAULT_DATE_FORMAT)
        end

        def process_api_lookups(gem_data_array)
          gem_data_array.each { |gem_data| process_single_api_lookup(gem_data) }
        end

        def process_single_api_lookup(gem_data) # rubocop:disable Metrics/MethodLength
          pkg = gem_data[:pkg]
          version_dates = fetch_gem_version_dates(pkg.name)
          final_dates = determine_final_dates(
            version_dates,
            pkg.version,
            gem_data[:latest_version],
            gem_data[:local_version_date],
            gem_data[:latest_version_date]
          )

          store_package(pkg)
          pkg.update(
            latest_version: gem_data[:latest_version],
            version_date: final_dates[:local],
            latest_version_date: final_dates[:latest]
          )
        end

        def determine_final_dates(version_dates, local_version, latest_version, local_date, latest_date)
          return fallback_to_local_dates(local_date, latest_date) unless version_dates

          {
            local: format_date(resolve_date(version_dates[local_version], local_date)),
            latest: format_date(resolve_date(version_dates[latest_version], latest_date))
          }
        end

        def resolve_date(api_date, fallback_date)
          api_date || (needs_api_lookup?(fallback_date) ? nil : fallback_date)
        end

        def fallback_to_local_dates(local_date, latest_date)
          {
            local: local_date.strftime(DEFAULT_DATE_FORMAT),
            latest: latest_date.strftime(DEFAULT_DATE_FORMAT)
          }
        end

        def fetch_gem_version_dates(gem_name)
          uri = build_api_uri(gem_name)
          response = make_http_request(uri)

          return nil unless success_response?(response)

          parse_version_dates(response.body)
        rescue StandardError => e
          log_api_error(gem_name, e) if debug_mode?
          nil
        end

        def build_api_uri(gem_name)
          URI("#{RUBYGEMS_API_BASE}/#{gem_name}.json")
        end

        def make_http_request(uri)
          http = create_http_client(uri)
          http.request(Net::HTTP::Get.new(uri))
        end

        def success_response?(response)
          response.code == '200'
        end

        def debug_mode?
          ENV.fetch('DEBUG', nil)
        end

        def log_api_error(gem_name, error)
          warn "Warning: Failed to fetch version dates for #{gem_name}: #{error.message}"
        end

        def create_http_client(uri)
          Net::HTTP.new(uri.host, uri.port).tap do |http|
            http.use_ssl = true
            http.read_timeout = HTTP_READ_TIMEOUT
            http.open_timeout = HTTP_OPEN_TIMEOUT
          end
        end

        def parse_version_dates(response_body)
          versions = JSON.parse(response_body)
          versions.each_with_object({}) do |version_info, dates|
            dates[version_info['number']] = version_info['created_at']
          end
        end

        def format_date(date_string)
          return 'N/A' if date_string.nil?

          Time.parse(date_string).strftime(DEFAULT_DATE_FORMAT)
        rescue StandardError
          'N/A'
        end

        def assign_groups
          definition = build_bundler_definition
          groups = definition.groups.uniq.sort
          groups.each { |group| update_gem_groups(definition, group) }
        end

        def build_bundler_definition
          definition = Bundler::Definition.build Pathname("#{@dir}/Gemfile"), Pathname("#{@dir}/Gemfile.lock"), nil
          Bundler.ui.level = 'error'
          definition.resolve_remotely!
          definition
        end

        def update_gem_groups(definition, group)
          specs = definition.specs_for([group])
          specs.each do |spec|
            next unless @gem_hash.key?(spec.name)

            current_groups = @gem_hash[spec.name].groups
            updated_groups = (current_groups | [group]).map(&:to_s)
            @gem_hash[spec.name].update(groups: updated_groups)
          end
        end
      end
    end
  end
end
