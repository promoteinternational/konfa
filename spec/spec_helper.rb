$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")

require 'konfa'

class MyTestKonfa < Konfa::Base
  class << self
    def env_variable_prefix
      'PREF_'
    end

    def allowed_variables
      {
        :my_var         => 'default value',
        :default_is_nil => nil
      }
    end
  end
end

class MyOtherTestKonfa < Konfa::Base
  class << self
    def env_variable_prefix
      'OTHER_PREF_'
    end

    def allowed_variables
      {
        :my_var         => 'other default',
        :default_is_nil => 'no it is not'
      }
    end
  end
end
