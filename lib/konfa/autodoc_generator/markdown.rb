require 'konfa/autodoc_generator/base'

module Konfa
  module AutoDocGenerator
    class Markdown < Base
      def generate(variables)
        md_lines  = [header(konfa_class.name)]
        md_lines << "*Version: #{version}*" unless version.nil?

        variables.each do |variable|
          md_lines << header(variable.name, 2)
          md_lines << "Default: *#{variable.default}*"
          md_lines << variable.comment unless variable.comment.nil?
        end

        md_lines.join("\n\n")
      end

      private

      def header(text, level=1)
        "#{'#' * level} #{text}"
      end
    end
  end
end