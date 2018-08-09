# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
    module Segmentation

      class RuleSetBuilder
        attr_reader :root_resource

        def initialize(root_resource)
          @root_resource = root_resource
        end

        def build(boundary_type)
          boundary_name = boundary_name_for(boundary_type)
          boundary_data = resource_for(boundary_name)
          symbol_table = symbol_table_for(boundary_data)
          rules_for(boundary_data, symbol_table)
        end

        def exception_rule_for(exceptions)
          regex_contents = exceptions.map { |exc| Regexp.escape(exc) }.join("|")
          rule_for({ value: "(#{regex_contents})\\u0020 × ", id: 0 }, nil)
        end

        private

        def boundary_name_for(str)
          str.gsub(/(?:^|\_)([A-Za-z])/) { |s| $1.upcase } + 'Break'
        end

        def symbol_table_for(boundary_data)
          table = TwitterCldr::Parsers::SymbolTable.new
          boundary_data[:variables].each do |variable|
            id = variable[:id].to_s
            tokens = segmentation_parser.tokenize_regex(variable[:value])
            # note: variables can be redefined (add replaces if key already exists)
            table.add(id, resolve_symbols(tokens, table))
          end
          table
        end

        def resolve_symbols(tokens, symbol_table)
          tokens.inject([]) do |ret, token|
            if token.type == :variable
              ret += symbol_table.fetch(token.value)
            else
              ret << token
            end
            ret
          end
        end

        def rules_for(boundary_data, symbol_table)
          boundary_data[:rules].map do |data|
            rule_for(data, symbol_table)
          end
        end

        def rule_for(boundary_data, symbol_table)
          boundary_symbol, left, right = parse(boundary_data[:value], symbol_table)
          left = RuleVisitor.new(left).start || StateTable.new({}, 0)
          right = RuleVisitor.new(right).start || StateTable.new({}, 0)

          {
            id: boundary_data[:id],
            string: boundary_data[:value],
            boundary_symbol: boundary_symbol,
            left: finalize(left),
            right: finalize(right)
          }
        end

        def finalize(state_table)
          finalized = state_table.finalize
          { table: finalized.table, exit_state: finalized.exit_state }
        end

        def parse(text, symbol_table)
          segmentation_parser.parse(
            text, { symbol_table: symbol_table }
          )
        end

        def resource_for(boundary_name)
          root_resource[:segments][boundary_name.to_sym]
        end

        def segmentation_parser
          @segmentation_parser ||= TwitterCldr::Segmentation::Parser.new
        end

      end
    end
  end
end
