require 'konfa'

class KonfaBasic < Konfa::Base
  class << self
    def allowed_variables
      {
        :my_var         => 'default value',   # This is a variable
        :default_is_nil => nil,               # Doesn't really do anything
      }
    end
  end
end

class KonfaOneLineHash < Konfa::Base
  class << self
    def allowed_variables
      { :my_var_1 => 'default value', :my_var_2 => nil }
    end
  end
end

class KonfaMixedNewlines < Konfa::Base
  class << self
    def allowed_variables
      { :my_var_1 => 'var 1', :my_var_2 => 'var 2',
        :my_var_3 => nil, my_var_4: 'var 4' }
    end
  end
end

class KonfaMultipleHashes < Konfa::Base
  class << self
    def allowed_variables
      hash_1 = {
        :my_var_1 => 'default value',
        :my_var_2 => nil,
      }
      hash_2 = {
        :my_var_3 => 'value 3',   # Comment here
        :my_var_4 => "value 4",
      }

      hash_1.merge(hash_2)
    end
  end
end

class KonfaMixedKeyStyles < Konfa::Base
  class << self
    def allowed_variables
      {
        new_style: 'default value',   # This is a variable
        :old_style => 'also default',  # This is documented
        also_new: 'Hey',
      }
    end
  end
end

class KonfaNoVariablesMethod < Konfa::Base
  class << self
  end
end

class KonfaBarewordAssignments < Konfa::Base

  A_CONSTANT = "it is"

  def method_call
    return 'who is there?'
  end

  class << self
    def allowed_variables
      {
        my_var_1: nil,
        my_var_2: method_call,
        my_var_3: @variable,
        my_var_4: @@class_variable,     # Comment here
        my_var_5: KonfaBarewordAssignments::A_CONSTANT,
        my_var_6: KonfaBarewordAssignments.method_call,
      }
    end
  end
end

class KonfaBlankLines < Konfa::Base
  class << self
    def allowed_variables
      {
        :my_var_1 => 'var 1',  # Comment 1
        :my_var_2 => 'var 2',  # Comment 2

        :my_var_3 => 'var 3',  # Comment 3

        :my_var_4 => 'var 4',  # Comment 4
      }

    end
  end
end

class KonfaMultiLineComments < Konfa::Base
  class << self
    def allowed_variables
      {
        :my_var_1 => 'var 1',  # Comment 1
        :my_var_2 => 'var 2',  # Comment 2...
                               # ...continues here
        :my_var_3 => 'var 3',  # Comment 3
        # Here is an off comment
        :my_var_4 => 'false',  # If true: this is on
                               # If false: this is off
        :my_var_5 => 'var 5',  # This :comment => looks like a hash declaration

      }
    end
  end
end

