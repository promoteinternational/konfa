Konfa
=====

Facilitates application configuration and tries to address a couple of common issues

 * Bugs attributed to misspelt configuration variable names
 * Forgotten configuration options that nobody knows what they do or where they are used
 * Seamlessly reading configuration values from either the environment or YAML (or any other source for that matter)

Basic Usage
-----------

```ruby
require 'konfa'

class MyAppConfig < Konfa::Base
  @@variables = {
    show_stuff: 'yes',             # You can describe what the variable's for here 
    stuff_id: nil,                 # ID of the stuff we're using
    lasers: 'off',
    tasers: 'on',
  }
end

# ... somewhere early in execution ..."

MyAppConfig.initialize_from_yaml('config/values.yaml')

# ... later on in the app ...

if MyAppConfig.true?(:show_stuff)
   SomeStuff.connect( MyAppConfig.get(:stuff_id) )
end

MyAppConfig.get(:no_such_variable) # Kabooom

```

@@variables
-----------

Valid configuration variables has to be declared in the @@variables hash. If you do not want to provide a default value, just use ```nil```.

Values
------
For the sake of simplicity, values are always converted to, and treated as, strings. You will have to cast it yourself if you need something else. The rationale behind this is to be able to initialize configuration values from sources that does not support specific datatypes (such as the environment)

Complex values, such as arrays or hashes, are not supported.

Booleans
--------
Because values are converted to strings, you can use the ```true?``` and ```false?``` methods to safely treat a value as a boolean. The strings ```"on"```, ```"1"```, ```"yes"``` and ```"true"``` will be treated as boolean true, and anything else (including nil) will be false.

So
```ruby
MyAppConfig.set(:bool, 'yes')
MyAppConfig.get(:bool) # => "yes"
MyAppConfig.true?(:bool) # => true
MyAppConfig.false?(:bool) # => false
```

Settings values
---------------
You *can* use the ```set``` method to set a value, but don't do that in your application code. It is, however, useful in tests and if implementing own initialisers.

with_config
-----------
The ```with_config``` method is useful for testing. It can be used like this

```ruby
MyAppConfig.set(:var, 'off')

MyAppConfig.with_config(:var => 'on') do
    MyAppConfig.get(:var) # => "on" inside this block
end

MyAppConfig.get(:var) # => "off" again
```

Original configuration values will be restored even if the block raises an exception. 

Values from environment
-----------------------
The ```initialize_from_env``` method populates values from the environment. Konfa will only import variables with a specific prefix to avoid collisions with existing variables.

```ruby
# in myapp.rb
class MyAppConfig < Konfa::Base
  @@env_variable_prefix = 'MYAPP_'
  @@variables = {
    show_stuff: 'yes',
    lang: 'sv',
  }
end

MyAppConfig.initialize_from_env

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

Values from YAML
----------------
The ```initialize_from_yaml``` will read values from the given yaml file. Only key/values are supported.

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
  @@variables = {
    log_file: nil,
  }
  def self.after_initialize
    Logger.file = get(:log_file)
  end
end
```
