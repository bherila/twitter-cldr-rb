# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class Rule
      attr_reader :left, :right, :id, :string

      def initialize(left, right, id, string)
        @left = left
        @right = right
        @id = id
        @string = string
        reset
      end

      def accept(codepoint)
        accepted = @current.accept(codepoint)

        if @current.current_state == 0
          reset
        elsif @left.terminal? && @current == @left
          @current = @right
        end

        accepted
      end

      def terminal?
        @left.terminal? && @right.terminal?
      end

      def reset
        @current = @left
        @current = @right if @left.empty?
        @left.reset
        @right.reset
      end

      def <(other)
        id < other.id
      end

      def >(other)
        id > other.id
      end
    end

    class BreakRule < Rule
      def boundary_symbol
        :break
      end

      def break?
        true
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
        true
      end
    end

  end
end
