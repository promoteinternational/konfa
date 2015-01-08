module Konfa
  module Initializer
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def init_with_yaml(path)
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

      def init_with_env
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
end
