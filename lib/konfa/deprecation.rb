module Konfa
  module Deprecation
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      @@deprecation_warnings = true

      def deprecation_warnings=(val)
        @@deprecation_warnings = val
      end

      def deprecation_warnings
        @@deprecation_warnings
      end

      def deprecated(*args)
        warn(*args) if @@deprecation_warnings
      end
    end
  end
end
