module Konfa
  module AutoDocGenerator
    class Base
      attr_reader :konfa_class
      attr_accessor :version

      def initialize(const, version=nil)
        @konfa_class = const
        @version = version
      end

      def generate
        autodoc = Konfa::AutoDoc.new(@konfa_class)
        format(autodoc.parse)
      end

      def format(variables)
        raise ImplementationMissing.new
      end

      class ImplementationMissing < StandardError; end
    end
  end
end
