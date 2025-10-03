require_relative '../util/bash_color'
require_relative 'base'

module Package
  module Audit
    module Formatter
      class Version < Formatter::Base
        def initialize(curr, target)
          super()
          @curr = curr
          @target = target
        end

        def format # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          return @curr if @target.nil? # No latest version available

          version_parts = @curr.split('.').map(&:to_i)
          latest_version_parts = @target.split('.').map(&:to_i)
          curr_tokens = @curr.split('.')

          if (version_parts.first || 0) < (latest_version_parts.first || 0)
            Util::BashColor.orange(@curr)
          elsif version_parts[1] && latest_version_parts[1] && version_parts[1] < latest_version_parts[1]
            "#{curr_tokens[0]}.#{Util::BashColor.yellow(curr_tokens[1..]&.join('.'))}"
          elsif version_parts[2] && latest_version_parts[2] && version_parts[2] < latest_version_parts[2]
            "#{curr_tokens[0..1]&.join('.')}.#{Util::BashColor.green(curr_tokens[2..]&.join('.'))}"
          elsif version_parts[3] && latest_version_parts[3] && version_parts[3] < latest_version_parts[3]
            "#{curr_tokens[0..2]&.join('.')}.#{Util::BashColor.green(curr_tokens[3])}"
          else
            @curr
          end
        end
      end
    end
  end
end
