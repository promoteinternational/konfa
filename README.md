konfa
=====

Facilitates application configuration and tries to address a couple of common issues

 * Bugs attributed to misspelt configuration variable names
 * Forgotten configuration options that nobody knows what they do or where they are used
 * Seamlessly reading configuration values from either the environment or YAML (or any other source for that matter)

Usage
-----

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


```
