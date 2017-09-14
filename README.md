Konfa
=====

[![Build Status](https://travis-ci.org/promoteinternational/konfa.svg)](https://travis-ci.org/promoteinternational/konfa)

Facilitates application configuration and tries to address a couple of common issues

 * Bugs attributed to misspelt configuration variable names
 * Forgotten configuration options that nobody knows what they do or where they are used
 * Seamlessly reading configuration values from either the environment or YAML (or any other source for that matter)

Basic Usage
-----------

```ruby
require 'konfa'

class MyAppConfig < Konfa::Base
  def self.allowed_variables
    {
      show_stuff: 'yes',             # You can describe what the variable is for here
      stuff_id: nil,                 # ID of the stuff we're using
      lasers: 'off',
      tasers: 'on',
    }
  end
end

# ... somewhere early in execution ..."

MyAppConfig.init_with(:yaml, 'config/values.yaml')

# ... later on in the app ...

if MyAppConfig.true?(:show_stuff)
   SomeStuff.connect( MyAppConfig.get(:stuff_id) )
end

MyAppConfig.get(:no_such_variable) # Kabooom

```

allowed_variables
-----------

Valid configuration variables has to be declared and returned by the ```allowed_variables``` hash. If you do not want to provide a default value, just use ```nil```.

Values
------
For the sake of simplicity, values are always converted to, and treated as, strings. The rationale behind this is to be able to initialize configuration values from sources that does not support specific datatypes (such as the environment)

Complex values, such as arrays or hashes, are not supported out of the box, but can easily be implemented if needed:

```ruby
class MyAppConfig < Konfa::Base
  def self.allowed_variables
    {
      :numbers => 'one, two, three'
    }
  end

  def self.as_list(key)
    get(key).split(/\s*,\s*/)
  end
end

MyAppConfig.get(:numbers)     => 'one,two,three'
MyAppConfig.as_list(:numbers) => ['one','two','three']
```


Booleans
--------
Because values are converted to strings, you can use the ```true?``` and ```false?``` methods to safely treat a value as a boolean. The strings ```"on"```, ```"1"```, ```"yes"``` and ```"true"``` will be treated as boolean true, and anything else (including nil) will be false.

So
```ruby
# given
#   :bool => 'yes'

MyAppConfig.get(:bool) # => "yes"
MyAppConfig.true?(:bool) # => true
MyAppConfig.false?(:bool) # => false
```

Settings values
---------------
Konfa does not provide an interface to set values. But if you *really* want to, you can do

```ruby
  MyAppConfig.send(:store, :key, 'value')
```

This could be useful for testing, but you really shouldn't set config values from within the application.

with_config
-----------
The ```with_config``` method is useful when code needs to be executed with
temporary settings. It can be used like this

```ruby
# given
#   :var => 'off'

MyAppConfig.with_config(:var => 'on') do
  MyAppConfig.get(:var) # => "on" inside this block
end

MyAppConfig.get(:var) # => "off" again
```

Original configuration values will be restored even if the block raises an exception.

This could be useful in testing. Another alternative is the RSpec plugin

Testing
-------

The RSpec plugin makes it easy to stub config variables with less typing manual
checking. It can be used like this


```ruby
require 'konfa/rspec'

describe Something
  include_context 'with konfa', MyKonfaSubclass

  it 'does something' do
    let_config(:my_variable, 'testing value')
    expect(code_that_returns_my_variable).to eq 'testing value'
  end
end
```

It will ensure ```my_variables``` exists and it will allow the tested code to be
executed with temporary values without having to worry about modifying global
configuration that may disrupt subsequent examples.

Populate with values from environment
-------------------------------------
Calling ```init_with(:env)``` populates values from the environment. Konfa will only import variables with a specific prefix to avoid collisions with existing variables.

```ruby
# in myapp.rb
class MyAppConfig < Konfa::Base

  def self.env_variable_prefix
    'MYAPP_'
  end

  def self.allowed_variables
    {
      show_stuff: 'yes',
      lang: 'sv'
    }
  end
end

MyAppConfig.init_with(:env)

puts "I speak #{MyAppConfig.get(:lang)} and I will #{MyAppConfig.true?(:show_stuff) ? "" : "not"} show stuff"
```

```bash
# In a console

$ export MYAPP_SHOW_STUFF=no
$ export MYAPP_LANG=pt
$ export LANG=en_US
$ ruby myapp.rb
I speak pt and I will not show stuff
```

Populate with values from YAML
------------------------------
The YAML initializer will read values from the given yaml file. Only key/values are supported.

*Note on YAML and booleans*

Ruby's YAML implementation will cast the words ```yes```, ```true```, ```on```, ```off```, ```false``` and ```no```
into a Boolean. This applies to both keys and values. Because Konfa assumes that all values are strings, values are
always converted to a String. This means that the word ```yes``` will result in the string ```"true"```.
To avoid this, please quote the word in your YAML source. Like so:

```YAML
---
my_key_1: yes     # Will result in Konfa.get(:my_key) => "true"
my_key_2: 'yes'   # Will result in Konfa.get(:my_key) => "yes"
```

after_initialize
----------------
Your subclass may implement a class method called ```after_initialize``` that will be called immediately after Konfa has
been initialized with configuration values. This is useful if you for example want to configure logging or something
else when you have to be sure that you have all config values.

Konfa's base implementation does nothing, so there's no point in calling ```super``` here.

```ruby
class MyAppConfig < Konfa::Base
  def self.allowed_variables
    {
      log_file: nil
    }
  end

  def self.after_initialize
    Logger.file = get(:log_file)
  end
end
```

Notes on initializing
-------------------

## Initialization is deferred by default

Konfa will initialize its values when a variable is first read (when for instance
calling `get`, `true?` or `dump`). Initialization can be triggered earlier by calling
the `init`method.

The default behaviour:

```ruby

MyAppConfig.init_with(:yaml, 'path_to_yaml_file')

# ... things happens, and later on in the execution:

MyAppConfig.get(:my_var) # Konfa will read the yaml file, populate the
                         # configuration and then return the value of `my_var`
```

Initialize earlier:

```ruby

MyAppConfig.init_with(:yaml, 'path_to_yaml_file')

MyAppConfig.init # Konfa will now read the yaml file and populate the configuration
                 # It's also possible to chain:
                 #     MyAppConfig.init_with(:yaml, '...').init

# ... things happens, and later on in the execution:

MyAppConfig.get(:my_var)
```

From a design perspective, it is desireble to initialize Konfa as early as possible,
as it will fail early if bad configuration values are found. Do not use this method
unless there is a good reason to.

You may override the ```init?``` method for implementing own logic on when to
run the initialization code. This method is invoked at every time a value is
accessed.

## Custom initialization methods

If you want to initialize Konfa with values from another source (for example a
database), you need to implement an initialization method. Extend the module
`Konfa::Initializer::ClassMethods` with your own method and call `init_with`.

***NOTE:*** your initializer method name must be prefixed with: `init_with_` to
avoid collisions in the configuration class.

```ruby

module Konfa
  module Initializer
    module ClassMethods
      def init_with_numbers
        self.store('my_var', '01234')
      end
    end
  end
end

class MyAppConfig < Konfa::Base
  def self.allowed_variables
    {
      my_var: nil,
    }
  end
end

MyAppConfig.init_with(:numbers) # Don't include prefix in symbol

MyAppConfig.get(:my_var) # => 01234
```
