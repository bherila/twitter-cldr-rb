# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class PossibleWord
      # list size, limited by the maximum number of words in the dictionary
      # that form a nested sequence.
      POSSIBLE_WORD_LIST_MAX = 20;

      def initialize
        @lengths = Array.new(POSSIBLE_WORD_LIST_MAX)
        @count = nil
        @offset = -1
      end

      # fill the list of candidates if needed, select the longest, and return the number found
      def candidates(cursor, dictionary, range_end)
        start = cursor.pos

        if start != @offset
          @offset = start
          @count, _, @lengths, @prefix = dict.matches(
            cursor.text, cursor.position, range_end - start, @lengths.length
          )

          # dictionary leaves text after longest prefix, not longest word. Back up.
          if @count <= 0
            cursor.position = start
          end
        end

        if @count > 0
          cursor.position = start + @lengths[@count - 1]
        end

        @current = @count - 1
        @mark = @current

        return @count
      end

      # select the currently marked candidate, point after it in the text, and invalidate self
      def accept_marked(cursor) {
        cursor.position = @offset + @lengths[@mark]
        @lengths[@mark]
      end

      # back up from the current candidate to the next shorter one; return true if that exists
      # and point the text after it
      def back_up(cursor) {
        if @current > 0
          cursor.position - @offset + @lengths[@current]
          @current -= 1
          return true
        end

        false
      end

      # return the longest prefix this candidate location shares with a dictionary word
      def longest_prefix
        @prefix
      end

      # mark the current candidate as the one we like
      def mark_current
        @mark = @current
      end
    end
  end
end
