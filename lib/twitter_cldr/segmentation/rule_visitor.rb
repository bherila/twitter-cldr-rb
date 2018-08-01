module TwitterCldr
  module Segmentation

    class RuleVisitor
      include TwitterCldr::Shared
      include TwitterCldr::Parsers

      attr_reader :root

      def initialize(root)
        @root = root
      end

      def start
        visit(root)
      end

      private

      def visit_children(node)
        return [] unless node.respond_to?(:elements)
        node.elements.map { |child| visit(child) }
      end

      def visit(node)
        case node
          when UnicodeRegex
            visit_regex(node)
          when UnicodeRegexParser::Alternation
            visit_alternation(node)
          when UnicodeRegexParser::CharacterClass
            visit_character_class(node)
          when UnicodeRegexParser::CharacterRange
            visit_character_range(node)
          when UnicodeRegexParser::CharacterSet
            visit_character_set(node)
          when UnicodeRegexParser::Group
            visit_group(node)
          when UnicodeRegexParser::UnicodeString
            visit_unicode_string(node)
        end
      end

      def visit_regex(node)
        collapse(visit_children(node))
      end

      def visit_character_class(node)
        visit_set(node)
      end

      def visit_character_range(node)
        visit_set(node)
      end

      def visit_character_set(node)
        visit_set(node)
      end

      def visit_set(node)
        # enter the next state when character is recognized
        table = node.to_set.each_with_object(blank_table) do |cp, table|
          table[0][cp] = 1
        end

        quantify(StateTable.new(table, 1), node.quantifier)
      end

      def quantify(table, quantifier)
        if quantifier.min == 0
          # if we don't enter, skip to next state
          table[0][:else] = table.exit_state
        end

        if quantifier.max == Float::INFINITY
          table[0].each do |cp, _|
            table[table.exit_state][cp] = table.exit_state
          end

          new_exit_state = table.exit_state + 1
          table[table.exit_state][:else] = new_exit_state
          table[0][:else] = new_exit_state if quantifier.min == 0
        end

        table
      end

      def visit_alternation(node)
        alternates = node.elements.map do |alt_group|
          collapse(alt_group.map { |alt_elem| visit(alt_elem) })
        end

        exit_states = Set.new

        alternates = collapse(alternates) do |first, second|
          new_second = second.shift_by(first.exit_state)
          exit_states << first.exit_state
          exit_states << new_second.exit_state
          result = { 0 => first.table[0].merge(new_second.table[first.exit_state]) }
          (first.table.keys - [0]).each { |k| result[k] = first.table[k] }
          new_second.table.delete(first.exit_state)
          result.merge!(new_second.table)
          StateTable.new(result, new_second.exit_state)
        end

        max_exit_state = exit_states.max

        alternates = alternates.rewrite_next_states do |next_state|
          next max_exit_state if exit_states.include?(next_state)
          next_state
        end

        StateTable.new(alternates.table, max_exit_state)
      end

      def visit_group(node)
        quantify(visit_children(node).first, node.quantifier)
      end

      def visit_unicode_string(node)
        codepoints = node.to_set.to_full_a
        table = blank_table
        exit_state = 0

        node.to_set.each_with_index do |cp, idx|
          table[idx][cp] = idx + 1
          exit_state = idx + 1
        end

        quantify(StateTable.new(table, exit_state), node.quantifier)
      end

      private

      def collapse(tables)
        return tables.first if tables.size <= 1

        tables[1..-1].inject(tables.first) do |ret, table|
          if block_given?
            yield ret, table
          else
            ret.merge(table)
          end
        end
      end

      def blank_table
        Hash.new { |h, k| h[k] = {} }
      end
    end

  end
end
