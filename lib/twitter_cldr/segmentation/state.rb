module TwitterCldr
  module Segmentation

    class State
      attr_reader :state_table, :current_state, :num_accepted

      EMPTY_TRANSITION = {}.freeze

      def initialize(state_table)
        @state_table = state_table
        reset
      end

      def accept(cp)
        if found = current[cp]
          @current_state = found
          @num_accepted += 1
          return true
        elsif current.include?(:else)
          next_state = current

          loop do
            # The idea is that if a state contains an :else we can skip past
            # it without issue. This line returns false at the end of an :else
            # chain because technically the character wasn't accepted. For that
            # reason, be sure to call terminal? after each call to accept - just
            # because accept returns false doesn't mean the state hasn't changed.
            return false unless next_state

            if next_state.include?(cp)
              @current_state = next_state[cp]
              @num_accepted += 1
              return true
            elsif next_state.include?(:else)
              @current_state = next_state[:else]
              next_state = state_table[next_state[:else]]
            else
              reset
              return false
            end
          end
        else
          reset
        end

        false
      end

      def terminal?
        current_state == state_table.exit_state
      end

      def reset
        @current_state = 0
        @num_accepted = 0
      end

      private

      def current
        state_table[current_state] || EMPTY_TRANSITION
      end
    end

  end
end
