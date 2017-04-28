require "method_source"

module Konfa

  AutoDocVariable = Struct.new(:name, :default, :comment)

  class AutoDoc
    attr_reader :variables, :konfa_class

    def initialize(const)
      @variables = []
      @konfa_class = const
    end

    RE_VAR = /
      (?:
        :(\w+)\s*=>           # 0: Old style hash key declaration - ":key => 'value'"
        |                     #   - or -
        (\w+):                # 1: New style hash key declaration - "key: 'value'"
      )
      \s*
      (?:
        (?:'|")(.+?)(?:'|")   # 2: A string constant (FIXME: Backref)
        |                     #   - or -
        ([\w\@\:\.]+)         # 3: Bareword
      )
      \s*
      ,?                      #   - an optional comma -
      \s*
      (?:\#\s*(.+?)\n)?       # 4: An optional comment
    /x

    def parse
      @variables = []
      code = @konfa_class.method(:allowed_variables).source
      code.scan(RE_VAR).each do |tokens|
        @variables << AutoDocVariable.new(
          tokens[0] || tokens[1],
          tokens[2] || tokens[3],
          tokens[4]
        )
      end

      variables
    end
  end
end
