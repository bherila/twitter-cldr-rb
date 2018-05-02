# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class Rule
      attr_reader :left, :right, :id

      def initialize(left, right, id)
        @index = 0
        @left = left
        @right = right
        @id = id
      end

      def accept(codepoint)
        if @left.satisfied? && @right.can_accept?(codepoint)
          @index += 1
        end

        current.accept(codepoint)
      end

      def terminal?
        @index > 0
      end

      def satisfied?
        @right.satisfied?
      end

      def reset
        @index = 0
        @left.reset
        @right.reset
      end

      private

      def current
        terminal? ? @right : @left
      end
    end

    class BreakRule < Rule
      def boundary_symbol
        :break
      end

      def break?
        terminal? && satisfied?
      end

      def no_break?
        false
      end
    end

    class NoBreakRule < Rule
      def boundary_symbol
        :no_break
      end

      def break?
        false
      end

      def no_break?
        terminal? && satisfied?
      end
    end

  end
end
