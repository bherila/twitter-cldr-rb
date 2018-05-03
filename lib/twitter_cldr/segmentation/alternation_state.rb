# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class AlternationState
      def initialize(element)
        @children = element.alternates.map { |a| State.wrap(a) }
        @quantifier_min = quantifier.min
        @quantifier_max = quantifier.max
      end

      def accept(codepoint)
        accepted = false

        0.upto(@children.size - 1) do |idx|
          accepted = true if @children[idx].accept(codepoint)
        end

        @num_accepted += 1 if accepted
        accepted
      end

      def can_accept?(codepoint)
        # return true if any of the alternates can accept
        0.upto(@children.size - 1) do |idx|
          return true if @children[idx].can_accept?(codepoint)
        end

        false
      end

      def satisfied?
        return false unless @num_accepted >= @quantifier_min && @num_accepted <= @quantifier_max

        # return true if at least one alternate is satisfied
        0.upto(@children.size - 1) do |idx|
          return true if @children[idx].satisfied?
        end

        false
      end

      def terminal?
        true
      end

      def reset
        @num_accepted = 0
        @children.each(&:reset)
      end

      private

      def quantifier
        @quantifier ||= if @element.respond_to?(:quantifier)
          @element.quantifier
        else
          TwitterCldr::Parsers::UnicodeRegexParser::Quantifier.blank
        end
      end
    end

  end
end
