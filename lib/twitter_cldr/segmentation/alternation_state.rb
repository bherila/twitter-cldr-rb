# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class AlternationState
      attr_reader :alternates

      def initialize(element)
        @element = element
        @alternates = element.alternates.map do |a|
          AlternationGroup.new(self, a)
        end
      end

      def accept(codepoint)
        accepted = false

        0.upto(@alternates.size - 1) do |idx|
          accepted = true if @alternates[idx].accept(codepoint)
        end

        accepted
      end

      def satisfied?
        # return true if at least one alternate is satisfied
        0.upto(@alternates.size - 1) do |idx|
          return true if @alternates[idx].satisfied?
        end

        false
      end

      def can_accept?(codepoint)
        # return true if any of the alternates can accept
        0.upto(@alternates.size - 1) do |idx|
          return true if @alternates[idx].can_accept?(codepoint)
        end

        false
      end

      def reset
        @alternates.each(&:reset)
      end

      def quantifier
        @quantifier ||= if @element.respond_to?(:quantifier)
          @element.quantifier
        else
          TwitterCldr::Parsers::UnicodeRegexParser::Quantifier.blank
        end
      end
    end

    class AlternationGroup
      attr_reader :element, :children

      def initialize(element, children)
        @element = element
        @children = children.map { |child| State.new(child) }
        @quantifier_min = element.quantifier.min
        @quantifier_max = element.quantifier.max
        @num_accepted = 0
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
        # return false unless @num_accepted >= @quantifier_min && @num_accepted <= @quantifier_max

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
    end

  end
end
