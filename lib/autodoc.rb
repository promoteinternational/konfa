require_relative 'konfa'
require 'method_source'


class MyTest < Konfa::Base

  def allowed_variables
    {
      :blah => 'variable',    # This is a variable
      :setting => nil,        # Here's anoher
      :no_comment => '0',
    }
  end
end


module Konfa
  class AutoDoc
    def initialize(const)
      @variables = []
      @konfa_class = const
    end

    RE_VAR = /
      (?:
        :(\w+)\s*=>
        |
        (\w+):
      )
      \s*
      (['"\w]+)
      \s*
      ,?
      \s*
      (?:\#\s*(.+?)\n)?
    /x

    def parse
      src = @konfa_class.instance_method(:allowed_variables).source

      src.scan(RE_VAR).each do |tokens|
        name = tokens[0] || tokens[1]
        value = tokens[2]
        comment = tokens[3]
        puts "#{tokens}"
        @variables << Variable.new(name, value, comment)
      end
      @variables[0].name
    end
  end

  class Variable
    attr_accessor :name, :default, :comment

    def initialize(name, default, comment)
      @name = name
      @default = default
      @comment = comment
    end
  end
end


doc = Konfa::AutoDoc.new(MyTest)

puts doc.parse()
