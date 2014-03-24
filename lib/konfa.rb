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

      attr_writer :configuration, :features

      def configuration
        @configuration ||= self.allowed_variables
      end

      def features
        @features ||= allowed_features
      end

      def truthy?(value)
        (!value.nil? && value =~ /^\s*(?:true|1|yes|on)\s*$/i) ? true : false
      end

      def store(collection, key, value)
        key = key.to_sym
        raise UnsupportedVariableError.new("#{collection}: #{key}") unless self.send(collection).has_key? key
        self.send(collection)[key] = value.to_s
      end

      public


      #
      # The following methods should be overridden and used to configure the
      # configuration class
      #

      def env_variable_prefix
        'APP_'
      end

      def features_prefix
        'feature'
      end

      def allowed_variables
        {}
      end

      def allowed_features
        {}
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

      def feature?(name)
        raise UnsupportedVariableError.new(name) unless self.features.has_key? name
        self.truthy?(self.features[name])
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

      def initialize_from_yaml(path)
        # FIXME: It would be a lot cleaner if the YAML library would raise an
        # exception if it fails to read the file. We'll handle it like this for now
        # load_file just returns "false" if it fails
        yaml_data = YAML.load_file(path)
        yaml_data.each do |variable, value|
          next if variable == self.features_prefix

          self.store(:configuration, variable, value)
        end

        yaml_data.fetch(self.features_prefix, {}).each do |feature, state|
          self.store(:features, feature, state)
        end

        after_initialize
        dump
      end

      def initialize_from_env
        conf_prefix = self.env_variable_prefix.upcase
        feat_prefix = self.features_prefix.downcase + "_"

        ENV.keys.reject { |key|
          key !~ /^#{conf_prefix}/ # Ignore everything that doesn't match the prefix
        }.each { |key|
          variable = key[conf_prefix.size..-1].downcase

          if variable =~ /^#{feat_prefix}/
            variable   = variable[feat_prefix.size..-1]
            collection = :features
          else
            collection = :configuration
          end

          self.store(collection, variable, ENV[key])
        }
        after_initialize
        dump
      end

      def after_initialize
      end

      def with_config(overrides={})
        original_config = dump
        overrides.each_pair {|k,v| self.store(:configuration, k, v) }

        begin
          result = yield
        ensure
          self.configuration = original_config
        end

        result
      end

      def with_features(overrides={})
        original_features = self.features.dup
        overrides.each_pair {|k,v| self.store(:features, k, v) }

        begin
          result = yield
        ensure
          self.features = original_features
        end

        result
      end
    end
  end

  class InitializationError < StandardError
  end

  class UnsupportedVariableError < StandardError
  end
end
