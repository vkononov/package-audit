module Package
  module Audit
    module Const
      module Fields
        AVAILABLE = %i[
          name
          version
          version_date
          latest_version
          latest_version_date
          flags
          vulnerabilities
          risk_type
        ]

        DEFAULT = %i[name version latest_version latest_version_date flags vulnerabilities risk_type]

        # the names of these fields must match the instance variables in the Dependency class
        HEADERS = {
          name: 'Package',
          version: 'Version',
          version_date: 'Version Date',
          latest_version: 'Latest',
          latest_version_date: 'Latest Date',
          flags: 'Flags',
          vulnerabilities: 'Vulnerabilities',
          risk_type: 'Risk'
        }
      end
    end
  end
end
