# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class State
      def self.wrap(element)
        case element
          when TwitterCldr::Parsers::UnicodeRegexParser::Alternation
            AlternationState.new(element)
          when TwitterCldr::Shared::UnicodeRegex
            State.new(nil, element.elements)
          else
            # don't use a bare 'new' here since self.wrap is also inherited
            # by derived classes
            State.new(element)
        end
      end

      attr_reader :num_accepted

      def initialize(element, children = nil)
        @element = element
        @quantifier_min = quantifier.min
        @quantifier_max = quantifier.max

        @children = if (children || element).respond_to?(:each)
          (children || element).map { |elem| self.class.wrap(elem) }
        end

        @children = nil if @children.empty?

        reset
      end

      def accept(codepoint)
        if @children
          return false if @children.empty?

          if @children[@index].satisfied? && @children[@index + 1] && @children[@index + 1].can_accept?(codepoint)
            @index += 1
          elsif terminal? && @children[@index].satisfied? && @children[0].can_accept?(codepoint)
            @index = 0  # reset
          end

          @children[@index].accept(codepoint).tap do
            if terminal? && @children[@index].satisfied?
              @num_accepted += 1
            end
          end
        else
          can_accept?(codepoint).tap do |accepted|
            @num_accepted += 1 if accepted
          end
        end
      end

      def can_accept?(codepoint)
        if @children
          @children[@index].can_accept?(codepoint)
        else
          return true unless @element

          set.include?(codepoint) &&
            @num_accepted < @quantifier_max
        end
      end

      def satisfied?
        return true if blank?
        return true if @num_accepted >= @quantifier_min && @num_accepted <= @quantifier_max
        return true unless @children

        @index.upto(@children.size - 1) do |idx|
          return false if !@children[idx].satisfied?
        end

        true
      end

      def terminal?
        return true if blank?
        return true unless @children
        return true unless @children[@index + 1]

        @index.upto(@children.size - 1) do |idx|
          return false if !@children[idx].terminal?
        end

        true
      end

      def blank?
        !@children && !@element
      end

      def reset
        @index = 0
        @num_accepted = 0
        @children && @children.each(&:reset)
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
