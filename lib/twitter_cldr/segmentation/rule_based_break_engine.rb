# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class RuleBasedBreakEngine
      attr_reader :locale, :rule_set, :use_uli_exceptions
      alias :use_uli_exceptions? :use_uli_exceptions

      def self.create(locale, boundary_type, options = {})
        new(locale, RuleSetLoader.load(locale, boundary_type), options)
      end

      def initialize(locale, rule_set, options = {})
        @locale = locale
        @rule_set = rule_set.map { |loaded_rule| loaded_rule.to_rule }

        @implicit_break = BreakRule.new(
          RuleSetLoader.build_state(TwitterCldr::Shared::UnicodeRegex.compile('')),
          RuleSetLoader.build_state(TwitterCldr::Shared::UnicodeRegex.compile('')),
          :implicit_break
        )

        @use_uli_exceptions = options.fetch(
          :use_uli_exceptions, false
        )

        @boundary_cache = {}
      end

      def each_boundary(cursor, end_pos = cursor.length)
        return to_enum(__method__, cursor, end_pos) unless block_given?

        rule_set.each(&:reset)
        last_boundary = cursor.position

        # implicit start of text boundary
        yield 0 if cursor.position == 0

        until cursor.position >= end_pos
          rule = find_match(cursor)

          if rule.break? && cursor.position != last_boundary
            yield cursor.position
            last_boundary = cursor.position
          end

          cursor.advance
        end

        # implicit end of text boundary
        yield end_pos if last_boundary < end_pos
      end

      private

      def each_rule(&block)
        return to_enum(__method__) unless block_given?
        # @TODO: handle ULI exceptions
        # yield exception_rule if use_uli_exceptions? && supports_exceptions?
        rule_set.each(&block)
      end

      def exception_rule
        @exception_rule ||= RuleSetLoader.exception_rule_for(
          locale, boundary_type
        )
      end

      def supports_exceptions?
        boundary_type == 'sentence'
      end

      def find_match(cursor)
        each_rule(&:reset)
        counter = cursor.position
        rules = each_rule.to_a
        terminal_rules = []
        rule_positions = {}

        until rules.empty?
          rules.reject! do |rule|
            if rule.terminal?
              rule_positions[rule.id] = counter
              terminal_rules << rule
            elsif !rule.accept(cursor.codepoints[counter])
              # need to check terminal? again because we just called accept
              # on the rule
              if rule.terminal?
                rule_positions[rule.id] = counter
                terminal_rules << rule
              end

              true
            else
              false
            end
          end

          counter += 1
        end

        terminal_rules.each do |rule|
          pos = rule_positions[rule.id]
          @boundary_cache[pos - rule.right.num_accepted] ||= rule
        end

        if match = @boundary_cache[cursor.position]
          @boundary_cache.delete(cursor.position)
          match
        else
          @implicit_break
        end
      end
    end

  end
end
