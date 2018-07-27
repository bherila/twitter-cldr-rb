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
        # @rule_set << BreakRule.new(
        #   LoadedRule.build_state(TwitterCldr::Shared::UnicodeRegex.compile('[\u0000-\u10FFFF]')),
        #   :implicit_break
        # )
        @rule_set << BreakRule.new(
          LoadedRule.build_state(TwitterCldr::Shared::UnicodeRegex.compile('[\u0000-\u10FFFF]')),
          LoadedRule.build_state(TwitterCldr::Shared::UnicodeRegex.compile('[\u0000-\u10FFFF]')),
          :implicit_break
        )

        # @implicit_final_rule = BreakRule.new(State.new(nil, []), :implicit_final)
        @implicit_final_rule = BreakRule.new(State.new(nil), State.new(nil), :implicit_final)

        @use_uli_exceptions = options.fetch(
          :use_uli_exceptions, false
        )
      end

      def each_boundary(cursor, end_pos = cursor.length)
        return to_enum(__method__, cursor, end_pos) unless block_given?

        last_boundary = cursor.position

        until cursor.position >= end_pos
          rule, boundary_position = find_match(cursor)
          puts "#{cursor.position}: #{rule.id}"

          if rule.break?
            yield boundary_position
            last_boundary = boundary_position
          end

          if boundary_position == cursor.position
            cursor.advance
          else
            cursor.advance(
              boundary_position - cursor.position
            )
          end

          rule_set.each(&:reset)
        end
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
        each_rule do |rule|
          # next unless rule.id == 11
          # binding.pry if rule.id == 12
          binding.pry if cursor.position == 12 && rule.id == 9
          counter = cursor.position

          while counter < cursor.length && rule.accept(cursor.codepoints[counter])
            counter += 1
          end

          # binding.pry if cursor.position == 12 && rule.id == 8
          if rule.satisfied? # && rule.terminal?
            return [rule, cursor.position + rule.num_accepted]
          end

          if counter >= cursor.length
            return [@implicit_final_rule, cursor.length]
          end
        end

        nil  # we should never get here in practice
      end
    end

  end
end
