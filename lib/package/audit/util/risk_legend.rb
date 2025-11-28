require_relative '../const/time'
require_relative 'bash_color'

module Package
  module Audit
    module Util
      module RiskLegend
        def self.print # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          puts ' ' + Util::BashColor.blue('1. Check if the package has a security vulnerability.')
          puts '    If yes, the following vulnerability -> risk mapping is used:'
          puts "       - #{Util::BashColor.red('unknown')} vulnerability\t-> #{Util::BashColor.red('high')} risk"
          puts "       - #{Util::BashColor.red('critical')} vulnerability\t-> #{Util::BashColor.red('high')} risk"
          puts "       - #{Util::BashColor.red('high')} vulnerability\t-> #{Util::BashColor.red('high')} risk"
          puts "       - #{Util::BashColor.orange('medium')} vulnerability\t-> #{Util::BashColor.orange('medium')} risk"
          puts "       - #{Util::BashColor.orange('moderate')} vulnerability\t-> #{Util::BashColor.orange('medium')} risk" # rubocop:disable Layout/LineLength
          puts "       - #{Util::BashColor.yellow('low')} vulnerability\t-> #{Util::BashColor.yellow('low')} risk"

          puts

          puts ' ' + Util::BashColor.blue('2. Check the package for potential deprecation.')
          puts "    If no new releases by author for at least #{Const::Time::YEARS_ELAPSED_TO_BE_OUTDATED} years:"
          puts "       - assign the risk to\t-> #{Util::BashColor.orange('medium')} risk"

          puts

          puts ' ' + Util::BashColor.blue('3. Check if a newer version of the package is available.')

          puts '    If yes, assign risk as follows:'
          puts "       - #{Util::BashColor.orange('major version')} mismatch\t-> #{Util::BashColor.orange('medium')} risk" # rubocop:disable Layout/LineLength
          puts "       - #{Util::BashColor.yellow('minor version')} mismatch\t-> #{Util::BashColor.yellow('low')} risk"
          puts "       - #{Util::BashColor.green('patch version')} mismatch\t-> #{Util::BashColor.yellow('low')} risk"
          puts "       - #{Util::BashColor.green('build version')} mismatch\t-> #{Util::BashColor.yellow('low')} risk"

          puts

          puts ' ' + Util::BashColor.blue('4. Take the highest risk from the first 3 steps.')
          puts '    If two risks match in severity, use the following precedence:'
          puts "       - #{Util::BashColor.red('vulnerability')} > #{Util::BashColor.orange('deprecation')} > #{Util::BashColor.yellow('outdatedness')}" # rubocop:disable Layout/LineLength

          puts

          puts ' ' + Util::BashColor.blue('5. Check whether the package is used in production or not.')
          puts '    If a package is limited to a non-production group:'
          puts "       - cap risk severity to\t -> #{Util::BashColor.yellow('low')} risk"
        end
      end
    end
  end
end
