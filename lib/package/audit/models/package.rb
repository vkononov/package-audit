require_relative '../enum/group'
require_relative '../enum/risk_explanation'
require_relative '../enum/risk_type'
require_relative '../services/risk_calculator'
require_relative 'risk'

module Package
  module Audit
    class Package
      attr_reader :name, :version, :technology
      attr_accessor :groups, :version_date, :latest_version, :latest_version_date, :vulnerabilities

      def initialize(name, version, technology, **attr)
        @name = name.to_s
        @version = version.to_s
        @technology = technology.to_s
        @groups = []
        @vulnerabilities = []
        @risks = []
        update(**attr)
      end

      def full_name
        "#{name}@#{version}"
      end

      def update(**attr)
        attr.each { |key, value| instance_variable_set(:"@#{key}", value) }
      end

      def risk
        risks.max || Risk.new(Enum::RiskType::NONE)
      end

      def risks
        RiskCalculator.new(self).find
      end

      def risk?
        risks.any?
      end

      def group_list
        @groups.join(' ')
      end

      def vulnerabilities_grouped
        @vulnerabilities.group_by(&:itself).map { |k, v| "#{k}(#{v.length})" }.join('|')
      end

      def risk_type
        risk.type
      end

      def risk_explanation
        risk.explanation
      end

      def deprecated?
        risks.each do |risk|
          return true if risk.explanation == Enum::RiskExplanation::POTENTIAL_DEPRECATION
        end
        false
      end

      def outdated?
        risks.each do |risk|
          return true if [
            Enum::RiskExplanation::OUTDATED,
            Enum::RiskExplanation::OUTDATED_BY_MAJOR_VERSION
          ].include?(risk.explanation || '')
        end
        false
      end

      def vulnerable?
        risks.each do |risk|
          return true if risk.explanation == Enum::RiskExplanation::VULNERABILITY
        end
        false
      end

      def flags
        v = vulnerable? ? 'V' : '·'
        o = outdated? ? 'O' : '·'
        d = deprecated? ? 'D' : '·'
        "⦗#{v}#{o}#{d}⦘"
      end

      def to_csv(fields)
        fields.map { |field| send(field) }.join(',')
      end

      def to_s
        "#{@name} #{@version} - [#{@groups.sort.join(', ')}]"
      end
    end
  end
end
