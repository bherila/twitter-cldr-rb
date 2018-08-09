module TwitterCldr
  module Segmentation
    class StateTable
      attr_reader :table, :exit_state

      def initialize(table, exit_state)
        @table = table
        @exit_state = exit_state
      end

      def [](state)
        table[state]
      end

      def empty?
        table.empty?
      end
    end
  end
end
