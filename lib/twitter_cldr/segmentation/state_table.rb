module TwitterCldr
  module Segmentation

    class StateTable
      attr_reader :table, :exit_state

      def initialize(table, exit_state)
        @table = table
        @exit_state = exit_state
      end

      def inspect
        table.inspect
      end

      def [](state)
        table[state]
      end

      def each_transition
        return to_enum(__method__) unless block_given?

        table.each_pair do |state, transitions|
          transitions.each_pair do |cp, next_state|
            yield state, cp, next_state
          end
        end
      end

      def shift_by(offset)
        new_exit_state = 0

        result = each_transition.with_object(blank_table) do |(state, cp, next_state), ret|
          new_state = state + offset
          ret[new_state][cp] = next_state + offset
          new_exit_state = ret[new_state][cp] if ret[new_state][cp] > new_exit_state
        end

        self.class.new(result, new_exit_state)
      end

      def merge(other)
        result = other.shift_by(exit_state)
        self.class.new(table.merge(result.table), result.exit_state)
      end

      def rewrite_next_states
        new_exit_state = 0

        result = each_transition.with_object(blank_table) do |(state, cp, next_state), ret|
          ret[state][cp] = yield next_state
          new_exit_state = ret[state][cp] if ret[state][cp] > new_exit_state
        end

        self.class.new(result, new_exit_state)
      end

      private

      def blank_table
        Hash.new { |h, k| h[k] = {} }
      end
    end

  end
end
