module Konfa
  module RSpec
    shared_context 'with konfa' do |klass|
      before {
        @konfa_klass = klass
        @konfa_stubbed_klasses = []
      }

      def let_config(variable, value, use_klass=@konfa_klass)
        raise Konfa::UnsupportedVariableError.new(variable) unless use_klass.allowed_variables.has_key?(variable)
        raise Konfa::RSpec::BadValueError.new(value) unless value.kind_of?(String)

        unless @konfa_stubbed_klasses.include?(use_klass)
          allow(use_klass).to receive(:get).and_call_original
          @konfa_stubbed_klasses << use_klass
        end

        allow(use_klass).to receive(:get).with(variable).and_return(value)
      end

      def with_config(variables, use_klass=@konfa_klass)
        variables.each_pair do |var, val|
          let_config(var, val, use_klass)
        end
      end
    end

    class BadValueError < StandardError
      def initialize(msg)
        @type = msg.class.name
      end

      def to_s
        "Konfa requires values to be of type String, you passed #{@type}"
      end
    end
  end
end
