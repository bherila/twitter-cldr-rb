# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    # class Rule
    #   attr_reader :left, :right, :id

    #   def initialize(left, right, id)
    #     @left = left
    #     @right = right
    #     @id = id
    #     reset
    #   end

    #   def accept(codepoint)
    #     if @left.satisfied? && @right.can_accept?(codepoint)
    #       @index += 1
    #     end

    #     current.accept(codepoint)
    #   end

    #   def terminal?
    #     @index > 0 && @right.terminal?
    #   end

    #   def satisfied?
    #     @left.satisfied? && @right.satisfied?
    #   end

    #   def reset
    #     @index = 0
    #     @left.reset if @left
    #     @right.reset if @right

    #     # some rules have blank left/right sides
    #     @index = 1 if @left && @left.blank?
    #   end

    #   private

    #   def current
    #     terminal? ? @right : @left
    #   end
    # end

    # class Rule
    #   attr_reader :state, :id

    #   def initialize(state, id)
    #     @state = state
    #     @id = id
    #   end

    #   def accept(codepoint)
    #     state.accept(codepoint)
    #   end

    #   def satisfied?
    #     state.satisfied?
    #   end

    #   def reset
    #     state.reset
    #   end

    #   def num_accepted
    #     state.num_accepted
    #     # state.children.first.num_accepted
    #   end
    # end

    class Rule
      attr_reader :left, :right, :id

      def initialize(left, right, id)
        @left = left
        @right = right
        @id = id
        reset
      end

      def accept(codepoint)
        if @left.satisfied? && @right.can_accept?(codepoint)
          @index += 1
        end

        current.accept(codepoint)
      end

      def satisfied?
        @left.satisfied? && @right.satisfied?
      end

      def reset
        @index = 0
        @left.reset if @left
        @right.reset if @right

        # some rules have blank left/right sides
        @index = 1 if @left && @left.blank?
      end

      def num_accepted
        @left.num_accepted
      end

      private

      def current
        @index == 0 ? @left : @right
      end
    end

    class BreakRule < Rule
      def boundary_symbol
        :break
      end

      def break?
        # terminal? && satisfied?
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
        # terminal? && satisfied?
        true
      end
    end

  end
end
