# -*- coding: utf-8 -*-
require 'yaml'

module Konfa
  class Base
    class << self
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
        @configuration
      end

      def initializer
        @initializer ||= nil
      end

      def truthy?(value)
        (!value.nil? && value =~ /^\s*(?:true|1|yes|on)\s*$/i) ? true : false
      end

      def store(key, value)
        key = key.to_sym
        if self.allowed_variables.has_key? key
          # Access configuration variable directly to avoid calling init
          @configuration[key] = value.to_s
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

      def init
        return if self.initialized == true
        # Set to true before calling to prevent recursion if
        # an initializer is accessing the configuration
        self.initialized = true
        unless self.initializer.nil?
          self.send(self.initializer.first, *self.initializer[1..-1])
        end
        self.after_initialize
      end

      def reset_configuration
        self.initialized = false
        @configuration = self.allowed_variables
      end

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

      def initialize_with(method, *args)
        self.initializer = [method, *args]
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

      # FIXME: Move out to external package
      def initialize_from_yaml(path)
        # FIXME: It would be a lot cleaner if the YAML library would raise an
        # exception if it fails to read the file. We'll handle it like this for now
        # load_file just returns "false" if it fails
        yaml_data = YAML.load_file(path)

        unless yaml_data.nil?
          raise InitializationError.new("Bad YAML format, key/value pairs expected") unless yaml_data.kind_of?(Hash)

          yaml_data.each do |variable, value|
            self.store(variable, value)
          end
        end

        dump
      end

      # FIXME: Move out to external package
      def initialize_from_env
        conf_prefix = self.env_variable_prefix.upcase

        ENV.keys.reject { |key|
          key !~ /^#{conf_prefix}/ # Ignore everything that doesn't match the prefix
        }.each { |key|
          variable = key[conf_prefix.size..-1].downcase

          self.store(variable, ENV[key])
        }

        dump
      end
    end
  end

  class InitializationError < StandardError
  end

  class UnsupportedVariableError < StandardError
  end
end
