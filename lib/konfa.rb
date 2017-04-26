require_relative File.join(File.dirname(__FILE__), 'konfa', 'initializer')

module Konfa
  class Base
    include Konfa::Initializer

    class << self

      private

      def default_values
        self.allowed_variables.each do |key, value|
          if !value.nil? && !value.kind_of?(String)
            warn "[DEPRECATION] default value for #{key} will be automatically stringified in future versions"
          end
        end

        self.allowed_variables
      end

      protected

      #
      # The following methods are not a part of the public API. You may subclass
      # them, but remember that unless you scope them as protected or private,
      # they will then be public
      #

      attr_writer :configuration, :initializer, :initialized

      def initialized
        @initialized ||= false
      end

      def configuration
        self.init
        @configuration ||= default_values
      end

      def initializer
        @initializer ||= nil
      end

      def truthy?(value)
        (!value.nil? && value =~ /^\s*(?:true|1|yes|on)\s*$/i) ? true : false
      end

      def store(key, value)
        key = key.to_sym
        if self.configuration.has_key? key
          self.configuration[key] = value.to_s
        else
          self.on_key_missing(key, value)
        end
      end

      public

      #
      # The following methods should be overridden and used to configure the
      # configuration class
      #

      def env_variable_prefix
        'APP_'
      end

      def allowed_variables
        {}
      end

      def on_key_missing(key, value)
        raise UnsupportedVariableError.new(key)
      end

      #
      # The following methods provides the interface to this class
      #

      def get(variable)
        raise UnsupportedVariableError.new(variable) unless self.configuration.has_key? variable
        self.configuration[variable]
      end

      def true?(variable)
        self.truthy?(self.get(variable))
      end

      def false?(variable)
        self.true?(variable) == false
      end

      def variables
        self.configuration.keys
      end

      def dump
        self.configuration.dup
      end

      def init?
        !self.initialized && !self.initializer.nil?
      end

      def init
        return unless self.init?
        # Set to true before calling to prevent recursion if
        # an initializer is accessing the configuration
        self.initialized = true
        self.send(self.initializer.first, *self.initializer[1..-1])
        self.after_initialize
      end

      def init_with(suffix, *args)
        self.initializer = [:"init_with_#{suffix}", *args]
        self
      end

      def reinit
        self.initialized = false
      end

      def after_initialize
      end

      def with_config(overrides={})
        original_config = dump
        overrides.each_pair {|k,v| self.store(k, v) }

        begin
          result = yield
        ensure
          self.configuration = original_config
        end

        result
      end

    end
  end

  class UnsupportedVariableError < StandardError
  end
end
