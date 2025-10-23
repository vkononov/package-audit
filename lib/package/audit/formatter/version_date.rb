require_relative '../const/time'
require_relative '../util/bash_color'
require_relative 'base'

require 'time'

module Package
  module Audit
    module Formatter
      class VersionDate < Formatter::Base
        def initialize(date)
          super()
          @date = date
        end

        def format
          return 'unknown' if @date.nil? # Handle private packages

          seconds_since_date = (Time.now - Time.parse(@date)).to_i

          if seconds_since_date >= Const::Time::SECONDS_ELAPSED_TO_BE_OUTDATED
            Util::BashColor.yellow(@date)
          else
            @date
          end
        end
      end
    end
  end
end
