# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    class UnicodeSet

      attr_reader :set

      def initialize(initial = [])
        @set = TwitterCldr::Utils::RangeSet.new(initial)
      end

      def apply_pattern(pattern)
        re = TwitterCldr::Shared::UnicodeRegex.compile(pattern)

        re.elements.each do |element|
          element.to_set.ranges.each do |range|
            set << range
          end
        end

        self
      end

      def add(codepoint)
        set << (codepoint..codepoint)
        self
      end

      def add_set(unicode_set)
        set.union!(unicode_set.set)
        self
      end

      def each(&block)
        set.each(&block)
      end

      def include?(codepoint)
        set.include?(codepoint)
      end

    end
  end
end
