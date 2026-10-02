module Package
  module Audit
    module Npm
      # Evaluates npm semver ranges (as used in registry advisories) against an
      # installed version. Supports comparator sets joined by "||", hyphen
      # ranges, caret and tilde ranges, and x-ranges. A range that cannot be
      # understood is treated as matching, so an advisory is never silently
      # dropped because of unusual syntax.
      class SemverRange
        WILDCARDS = %w[* x X].freeze

        def initialize(range)
          @range = range.to_s.strip
        end

        def satisfied_by?(version)
          return true if @range.empty?

          installed = parse_version(version)
          return false if installed.nil?

          @range.split('||').any? { |set| comparator_set_matches?(set.strip, installed) }
        rescue ArgumentError
          true
        end

        private

        def comparator_set_matches?(set, installed)
          return true if set.empty? || WILDCARDS.include?(set)

          Gem::Requirement.new(*requirements_for(set)).satisfied_by?(installed)
        end

        def requirements_for(set)
          return hyphen_requirements(*set.split(/\s+-\s+/, 2)) if set.match?(/\s-\s/)

          set.split(/\s+/).flat_map { |comparator| comparator_requirements(comparator) }
        end

        def comparator_requirements(comparator)
          case comparator
          when /\A\^(.+)\z/ then caret_requirements(Regexp.last_match(1))
          when /\A~>?(.+)\z/ then tilde_requirements(Regexp.last_match(1))
          when /\A(>=|<=|>|<|=)\s*(.+)\z/ then operator_requirements(Regexp.last_match(1), Regexp.last_match(2))
          else x_range_requirements(comparator)
          end
        end

        def operator_requirements(operator, partial)
          parts = version_parts(partial)
          return [] if parts.empty?
          return ["#{operator} #{normalize(partial)}"] if parts.length == 3 || partial.include?('-')

          partial_operator_requirements(operator, fill(parts), bump(parts))
        end

        # ">=1.2" means >=1.2.0, ">1.2" means >=1.3.0, "<=1.2" means <1.3.0, "=1.2" means 1.2.x
        def partial_operator_requirements(operator, lower, upper)
          case operator
          when '>' then [">= #{upper}"]
          when '<=' then ["< #{upper}"]
          when '=' then [">= #{lower}", "< #{upper}"]
          else ["#{operator} #{lower}"]
          end
        end

        def hyphen_requirements(low, high)
          requirements = []
          requirements << ">= #{normalize(low)}" unless version_parts(low).empty?
          high_parts = version_parts(high)
          return requirements if high_parts.empty?

          requirements << (high_parts.length == 3 ? "<= #{normalize(high)}" : "< #{bump(high_parts)}")
        end

        def caret_requirements(partial)
          parts = version_parts(partial)
          return [] if parts.empty?

          # Bump the leftmost non-zero part, or the last given part when all are zero.
          index = parts.index(&:positive?) || (parts.length - 1)
          [">= #{normalize(partial)}", "< #{bump(parts.first(index + 1))}"]
        end

        def tilde_requirements(partial)
          parts = version_parts(partial)
          return [] if parts.empty?

          upper = parts.length == 1 ? "#{parts[0] + 1}.0.0" : "#{parts[0]}.#{parts[1] + 1}.0"
          [">= #{normalize(partial)}", "< #{upper}"]
        end

        def x_range_requirements(partial)
          parts = version_parts(partial)
          return [] if parts.empty?
          return ["= #{normalize(partial)}"] if parts.length == 3 && !partial.match?(/[xX*]/)

          [">= #{fill(parts)}", "< #{bump(parts)}"]
        end

        # Numeric leading parts of a version, stopping at the first wildcard.
        # "1.2.x" => [1, 2], "1.2.3-beta" => [1, 2, 3], "x" => []
        def version_parts(partial)
          partial.to_s.sub(/\A[v=]+/, '').sub(/[-+].*\z/, '').split('.').take_while do |part|
            part.match?(/\A\d+\z/)
          end.map(&:to_i)
        end

        def fill(parts)
          (parts + [0, 0, 0]).first(3).join('.')
        end

        def bump(parts)
          bumped = parts.dup
          bumped[-1] += 1
          fill(bumped)
        end

        # Gem::Version understands "1.2.3-beta.1" (as a prerelease) but not build
        # metadata, a leading "v", or missing patch numbers.
        def normalize(version)
          cleaned = version.to_s.sub(/\A[v=]+/, '').sub(/\+.*\z/, '')
          numeric, prerelease = cleaned.split('-', 2)
          numeric = numeric.to_s
          numeric = fill(numeric.split('.').map(&:to_i)) if numeric.match?(/\A\d+(\.\d+){0,2}\z/)
          prerelease ? "#{numeric}-#{prerelease}" : numeric
        end

        def parse_version(version)
          Gem::Version.new(normalize(version))
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
