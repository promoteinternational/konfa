require_relative File.join(File.dirname(__FILE__), 'konfa', 'initializer')
require_relative File.join(File.dirname(__FILE__), 'konfa', 'deprecation')

module Konfa
  class Base
    include Konfa::Initializer
    include Konfa::Deprecation

    class << self

      private

      def default_values
        self.allowed_variables.each do |key, value|
          if !value.nil? && !value.kind_of?(String)
            deprecated "[DEPRECATION] default value for #{key} will be automatically stringified in future versions"
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

      # [DEPRECATED] This method will be removed in favor of initialized? in Konfa 1.0
      def initialized
        @initialized ||= false
      end

      def configuration
        self.init
        @configuration ||= default_values
      end

      # [DEPRECATED] This attribute will be removed in Konfa 1.0
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

      def get!(variable)
        raise NilVariableError.new(variable) if self.get(variable).nil?
        self.get(variable)
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
        deprecated "[DEPRECATION] init? will be removed in Konfa 1.0, use initialized? instead"
        !self.initialized && !self.initializer.nil?
      end

      def init
        deprecated "[DEPRECATION] This style of initialization will no longer be supported in Konfa 1.0 and init "\
                   "will be removed. Use initialize! or read_from/initialized! instead"
        return unless self.init?
        # Set to true before calling to prevent recursion if
        # an initializer is accessing the configuration
        self.initialized = true
        self.send(self.initializer.first, *self.initializer[1..-1])
        self.after_initialize
      end

      def init_with(suffix, *args)
        deprecated "[DEPRECATION] init will be removed in Konfa 1.0. Use read_from instead"
        self.initializer = [:"init_with_#{suffix}", *args]
        self
      end

      def reinit
        deprecated "[DEPRECATION] reinit will be removed in Konfa 1.0. Use read_from to load multiple config files"
        self.initialized = false
      end

      def read_from(initializer, *files)
        raise UnsupportedInitializerError unless self.respond_to?(:"init_with_#{initializer}")

        if files.empty?
          self.send(:"init_with_#{initializer}")
        else
          files.each { |file| self.send(:"init_with_#{initializer}", file) }
        end

        self
      end

      def initialized!
        unless self.initialized?
          @initialized = true
          self.after_initialize
        end

        self
      end

      def initialize!(initializer, *files)
        self.read_from(initializer, *files)
        self.initialized!
      end

      def initialized?
        @initialized == true
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

  class UnsupportedInitializerError < StandardError; end
  class UnsupportedVariableError < StandardError; end
  class NilVariableError < StandardError; end
end
