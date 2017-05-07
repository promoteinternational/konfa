module Konfa
  module AutoDocGenerator
    class Base
      attr_reader :konfa_class, :version

      def initialize(const, version=nil)
        @konfa_class = const
        @version = version
      end
    end
  end
end