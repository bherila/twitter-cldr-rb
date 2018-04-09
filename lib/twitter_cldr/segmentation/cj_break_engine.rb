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

      def divide_up_dictionary_range(codepoints, start_pos, end_pos)
        codepoints = codepoints[start_pos..end_pos]
        best_snlp = Array.new(codepoints.size + 1) { LARGE_NUMBER }
        prev = Array.new(codepoints.size + 1) { -1 }

        best_snlp[0] = 0

        codepoints.each_with_index do |codepoint, idx|
          next if best_snlp[idx] == LARGE_NUMBER

          max_search_length = if idx + MAX_WORD_SIZE < codepoints.size
            MAX_WORD_SIZE
          else
            codepoints.size - idx
          end

          count, values, lengths, _ = dictionary.matches(
            codepoints, idx, max_search_length, max_search_length
          )

          if count == 0 || lengths[0] != 1
            values[count] = MAX_SNLP
            lengths[count] = 1
            count += 1
          end

          count.times do |j|
            new_snlp = best_snlp[idx] + values[j]

            if new_snlp < best_snlp[lengths[j] + idx]
              best_snlp[lengths[j] + idx] = new_snlp
              prev[lengths[j] + idx] = idx
            end
          end
        end

        t_boundary = []

        if best_snlp[codepoints.size] == LARGE_NUMBER
          t_boundary << codepoints.size
        else
          idx = codepoints.size

          while idx > 0
            t_boundary << idx
            idx = prev[idx]
          end
        end

        if t_boundary.empty? || t_boundary.last > start_pos
          t_boundary << 0
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
