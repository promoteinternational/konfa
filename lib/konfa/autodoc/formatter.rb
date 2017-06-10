module Konfa
  module AutoDoc
    class Formatter
      attr_reader :konfa_class
      attr_accessor :version

      def initialize(const, version=nil)
        @konfa_class = const
        @version = version
      end

      def generate
        autodoc = Konfa::AutoDoc::Parser.new(@konfa_class)
        format(autodoc.parse)
      end

      def format(variables)
        raise ImplementationMissing.new
      end

      class ImplementationMissing < StandardError; end
    end
  end
end
