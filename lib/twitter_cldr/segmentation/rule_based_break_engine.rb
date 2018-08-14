# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class RuleBasedBreakEngine
      attr_reader :locale, :rule_set

      def self.create(locale, boundary_type, options = {})
        new(locale, RuleSet.build_new(locale, boundary_type, options))
      end

      def initialize(locale, rule_set)
        @locale = locale
        @rule_set = rule_set
      end

      def each_boundary(cursor, end_pos = cursor.length)
        return to_enum(__method__, cursor, end_pos) unless block_given?

        rule_set.reset

        # implicit start boundary
        yield cursor.position
        last_boundary = cursor.position

        until cursor.position >= end_pos
          rule = rule_set.find_match(cursor)
          # puts [cursor.position, rule.id].inspect

          if rule.break? && cursor.position != last_boundary
            yield cursor.position
            last_boundary = cursor.position
          end

          cursor.advance
        end

        # implicit end of text boundary
        yield end_pos if last_boundary < end_pos
      end
    end

  end
end
