# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class State
      attr_reader :num_accepted, :children

      def initialize(element, children = nil)
        @element = element
        @quantifier_min = quantifier.min
        @quantifier_max = quantifier.max
        @children = children
        reset
      end

      def accept(codepoint)
        return accept_leaf(codepoint) unless @children
        return false unless @children[@index]

        if @children[@index].accept(codepoint)
          @num_accepted += 1
          return true
        end

        # find the next child in the chain that can accept the codepoint
        old_index = @index

        while @index < @children.size
          if @children[@index].can_accept?(codepoint)
            @num_accepted += 1
            return @children[@index].accept(codepoint)
          elsif @children[@index].satisfied?
            @index += 1
          else
            @index = old_index
            break
          end
        end

        if @index == @children.size - 1
          @index = 0
        end

        false
      end

      def accept_leaf(codepoint)
        can_accept?(codepoint).tap do |accepted|
          @num_accepted += 1 if accepted
        end
      end

      def can_accept?(codepoint)
        if @children
          return false unless @children[@index]
          @children[@index].can_accept?(codepoint)
        else
          return true unless @element

          set.include?(codepoint) &&
            @num_accepted < @quantifier_max
        end
      end

      def satisfied?
        return true if blank?

        if @children
          return true if @quantifier_min == 0

          @index.upto(@children.size - 1) do |idx|
            return false if !@children[idx].satisfied?
          end

          true
        else
          @num_accepted >= @quantifier_min && @num_accepted <= @quantifier_max
        end
      end

      def blank?
        !@children && !@element
      end

      def reset
        @index = 0
        @num_accepted = 0
        @children.each(&:reset) if @children
      end

      private

      def quantifier
        @quantifier ||= if @element.respond_to?(:quantifier)
          @element.quantifier
        else
          TwitterCldr::Parsers::UnicodeRegexParser::Quantifier.blank
        end
      end

      def set
        @set ||= if @element.respond_to?(:text)
          if @element.text == '.'
            TwitterCldr::Utils::RangeSet.new([0..0x10FFFF])
          end
        else
          range_set = @element.to_set

          if range_set.size > 30_000
            # don't turn this guy into an array, it's just
            # too damn large
            range_set
          else
            Set.new(range_set.to_full_a)
          end
        end
      end
    end

  end
end
