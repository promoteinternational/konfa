# -*- coding: utf-8 -*-
require 'yaml'

module Konfa
  class Base
    class << self
      protected

      #
      # The following methods are not a part of the public API. You may sublcass
      # them, but remember that unless you scope them as protected or private,
      # they will then be public
      #

      attr_writer :configuration, :deferred, :initialized_deferred

      def initialized_deferred
        @initialized_deferred ||= false
      end

      def configuration
        @configuration ||= self.allowed_variables
      end

      def deferred
        @deferred ||= nil
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

      def do_deferred_initialization
        self.send(self.deferred.first, *self.deferred[1..-1])
        self.initialized_deferred = true
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

      def do_deferred_initialization?
        !self.initialized_deferred && !self.deferred.nil?
      end

      #
      # The following methods provides the interface to this class
      #

      def get(variable)
        self.do_deferred_initialization if self.do_deferred_initialization?
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

      def initialize_deferred(method, *args)
        self.deferred = [method, *args]
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

        after_initialize
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

        after_initialize
        dump
      end
    end
  end

  class InitializationError < StandardError
  end

  class UnsupportedVariableError < StandardError
  end
end
