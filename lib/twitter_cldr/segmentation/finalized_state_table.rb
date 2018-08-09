module TwitterCldr
  module Segmentation

    class FinalizedStateTable
      attr_reader :table, :exit_state

      def initialize(table, exit_state)
        @table = table
        @exit_state = exit_state
      end

      def [](state)
        table[state]
      end

      def serialize
        {
          exit_state: exit_state,
          table: table.each_with_object({}) do |(state, transitions), ret|
            ret[state] = transitions.serialize
          end
        }
      end
    end

  end
end
