# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources
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
          if node.is_a?(UnicodeRegex)
            puts "\n"
          else
            puts node.class
          end

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
            when UnicodeRegexParser::Literal
              visit_literal(node)
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
          trie = TwitterCldr::Utils::Trie.new

          if $boundary_id == 7 && $boundary_type == 'sentence'
            alternates = node.elements.map do |alt_group|
              collapse(alt_group.map { |alt_elem| visit(alt_elem) })
            end

            binding.pry
          end

          node.elements.each do |alt_group|
            alternate = collapse(alt_group.map { |alt_elem| visit(alt_elem) })
            load_into_trie(alternate, [], 0, trie)
          end

          table = blank_table
          exit_state = trie_to_table(trie.root, table, 0, nil)
          table.delete(exit_state)
          table = StateTable.new(table, exit_state)

          table = table.rewrite_next_states do |next_state|
            next exit_state if next_state == :exit
            next_state
          end

          table = simplify(table)
          quantify(table, node.quantifier)
        end

        def n_intersection(arrs)
          shortest = nil
          rest = []

          arrs.each do |arr|
            shortest ||= arr

            if arr.size <= shortest.size
              shortest = arr
            else
              rest << arr
            end
          end

          shortest.each_with_object([]) do |item, ret|
            ret << item if rest.all? { |r| r.include?(item) }
          end
        end

        def simplify(table)
          while table[table.exit_state - 1] == { else: table.exit_state }
            table.table.delete(table.exit_state - 1)

            table = table.rewrite_next_states do |next_state|
              next table.exit_state - 1 if next_state == table.exit_state
              next_state
            end
          end

          table
        end

        def trie_to_table(root, table, state, parent_cp)
          if root.has_value?
            if root.value == :stay
              table[state][parent_cp] = state
            else
              table[state][:else] = :exit
            end
          end

          current_state = state

          root.each_key_and_child do |cp, child|
            table[current_state][cp] = state + 1
            state = trie_to_table(child, table, state + 1, cp)
          end

          state
        end

        def load_into_trie(table, cp_path, state, trie)
          puts cp_path.inspect if $boundary_id == 7 && $boundary_type == 'sentence'

          if state == table.exit_state
            trie.add(cp_path, :exit)
            return
          end

          table[state].each_pair do |cp, next_state|
            if state == next_state
              # avoid infinite recursion
              trie.add(cp_path, :stay)
            else
              load_into_trie(table, cp_path + [cp], next_state, trie)
            end
          end
        end

        def visit_group(node)
          quantify(collapse(visit_children(node)), node.quantifier)
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

        def visit_literal(node)
          if node.text == '.'
            quantify(StateTable.new({ 0 => { else: 1 } }, 1), node.quantifier)
          else
            visit_unicode_string(node)
          end
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
end
