# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    LoadedRule = Struct.new(:boundary_symbol, :left, :right, :id, :string) do
      def to_rule
        klass = case boundary_symbol
          when :break then BreakRule
          when :no_break then NoBreakRule
        end

        klass.new(State.new(left), State.new(right), id)
      end
    end

    class RuleSetLoader

      class << self
        def load(locale, boundary_type)
          rule_cache[boundary_type] ||= begin
            boundary_name = boundary_name_for(boundary_type)
            boundary_data = resource_for(boundary_name)
            symbol_table = symbol_table_for(boundary_data)
            rules_for(boundary_data, symbol_table)
          end
        end

        # See the comment above exceptions_for. Basically, we only support exceptions
        # for the "sentence" boundary type since the ULI JSON data doesn't distinguish
        # between boundary types.
        def exception_rule_for(locale, boundary_type)
          cache_key = TwitterCldr::Utils.compute_cache_key(locale, boundary_type)
          exceptions_cache[cache_key] ||= begin
            exceptions = exceptions_for(locale, boundary_type)
            regex_contents = exceptions.map { |exc| Regexp.escape(exc) }.join("|")
            parse("(?:#{regex_contents}) ×", nil).tap do |rule|
              rule.id = 0
            end
          end
        end

        private

        # The boundary_type param is not currently used since the ULI JSON resource that
        # exceptions are generated from does not distinguish between boundary types. The
        # XML version does, however, so the JSON will hopefully catch up at some point and
        # we can make use of this second parameter. For the time being, compile_exception_rule_for
        # (which calls this function) assumes a "sentence" boundary type.
        def exceptions_for(locale, boundary_type)
          exceptions_resource_cache[locale] ||= begin
            TwitterCldr.get_resource('uli', 'segments', locale)[locale][:exceptions]
          rescue Resources::ResourceLoadError
            []
          end
        end

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
            LoadedRule.new(
              *parse(data[:value], symbol_table), data[:id], data[:string]
            )
          end
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
          @segmentation_parser ||= Segmentation::Parser.new
        end

        def root_resource
          @root_resource ||= TwitterCldr.get_resource(
            'shared', 'segments', 'segments_root'
          )
        end

        def rule_cache
          @rule_cache ||= {}
        end

        def exceptions_resource_cache
          @exceptions_resource_cache ||= {}
        end

        def exceptions_cache
          @exceptions_cache ||= {}
        end
      end

    end
  end
end
