module Package
  module Audit
    module Const
      module Cmd
        BUNDLE_AUDIT = 'bundle-audit check --update'
        BUNDLE_AUDIT_JSON = %w[bundle-audit check --update --quiet --format json].freeze

        NPM_AUDIT = 'npm audit'
      end
    end
  end
end
