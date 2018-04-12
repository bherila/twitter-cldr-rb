# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class CjBreakEngine < DictionaryBreakEngine

      # magic number pulled from ICU's source code, presumably slightly longer
      # than the longest Chinese/Japanese/Korean word
      MAX_WORD_SIZE = 20

      # magic number pulled from ICU's source code
      MAX_SNLP = 255

      # the equivalent of Java's Integer.MAX_VALUE
      LARGE_NUMBER = 0xFFFFFFFF

      private

      def fset
        @fset ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[:Han:]')
          set.apply_pattern('[[:Katakana:]\uff9e\uff9f]')
          set.apply_pattern('[:Hiragana:]')
          set.add(0xFF70)  # HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK
          set.add(0x30FC)  # KATAKANA-HIRAGANA PROLONGED SOUND MARK
        end
      end

      def divide_up_dictionary_range(cursor, end_pos)
        best_snlp = Array.new(cursor.length + 1) { LARGE_NUMBER }
        prev = Array.new(cursor.length + 1) { -1 }

        best_snlp[0] = 0
        start_pos = cursor.position

        until cursor.eos?
          if best_snlp[cursor.position] == LARGE_NUMBER
            cursor.advance
            next
          end

          max_search_length = if cursor.position + MAX_WORD_SIZE < cursor.length
            MAX_WORD_SIZE
          else
            cursor.length - cursor.position
          end

          count, values, lengths, _ = dictionary.matches(
            cursor.text, cursor.position, max_search_length, max_search_length
          )

          if count == 0 || lengths[0] != 1
            values[count] = MAX_SNLP
            lengths[count] = 1
            count += 1
          end

          count.times do |j|
            new_snlp = best_snlp[cursor.position] + values[j]

            if new_snlp < best_snlp[lengths[j] + cursor.position]
              best_snlp[lengths[j] + cursor.position] = new_snlp
              prev[lengths[j] + cursor.position] = cursor.position
            end
          end

          cursor.advance
        end

        t_boundary = []

        if best_snlp[cursor.length] == LARGE_NUMBER
          t_boundary << codepoints.size
        else
          idx = cursor.length

          while idx > 0
            t_boundary << idx
            idx = prev[idx]
          end
        end

        t_boundary.reverse
      end

      private

      def dictionary
        @dictionary ||= Dictionary.cj
      end

    end
  end
end
