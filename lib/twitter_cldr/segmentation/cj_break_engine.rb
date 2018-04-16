# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class CjBreakEngine < DictionaryBreakEngine

      include Singleton

      # magic number pulled from ICU's source code, presumably slightly longer
      # than the longest Chinese/Japanese/Korean word
      MAX_WORD_SIZE = 20

      # magic number pulled from ICU's source code
      MAX_SNLP = 255

      # the equivalent of Java's Integer.MAX_VALUE
      LARGE_NUMBER = 0xFFFFFFFF

      MAX_KATAKANA_LENGTH = 8
      MAX_KATAKANA_GROUP_LENGTH = 20
      KATAKANA_COSTS = [8192, 984, 408, 240, 204, 252, 300, 372, 480]

      def self.word_set
        @word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[:Han:]')
          set.apply_pattern('[[:Katakana:]\uff9e\uff9f]')
          set.apply_pattern('[:Hiragana:]')
          set.add(0xFF70)  # HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK
          set.add(0x30FC)  # KATAKANA-HIRAGANA PROLONGED SOUND MARK
        end
      end

      private

      def word_set
        self.class.word_set
      end

      def divide_up_dictionary_range(cursor, end_pos)
        best_snlp = Array.new(cursor.length + 1) { LARGE_NUMBER }
        prev = Array.new(cursor.length + 1) { -1 }

        best_snlp[0] = 0
        start_pos = cursor.position
        is_prev_katakana = false

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
            cursor, max_search_length, max_search_length
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

          # In Japanese, single-character Katakana words are pretty rare.
          # Accordingly, we apply the following heuristic: any continuous
          # run of Katakana characters is considered a candidate word with
          # a default cost specified in the katakanaCost table according
          # to its length.
          is_katakana = is_katakana?(cursor.current_cp)

          if !is_prev_katakana && is_katakana
            j = cursor.position + 1
            cursor.advance

            while j < cursor.length && (j - cursor.position) < MAX_KATAKANA_GROUP_LENGTH && is_katakana?(cursor.current_cp)
              cursor.advance
              j += 1
            end

            if (j - cursor.position) < MAX_KATAKANA_GROUP_LENGTH
              new_snlp = best_snlp[cursor.position] + get_katakana_cost(j - cursor.position)

              if new_snlp < best_snlp[j]
                best_snlp[j] = new_snlp
                prev[j] = cursor.position
              end
            end
          end

          is_prev_katakana = is_katakana
        end

        t_boundary = []

        if best_snlp[cursor.length] == LARGE_NUMBER
          t_boundary << cursor.length
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

      def is_katakana?(codepoint)
        (codepoint >= 0x30A1 && codepoint <= 0x30FE && codepoint != 0x30FB) ||
          (codepoint >= 0xFF66 && codepoint <= 0xFF9F)
      end

      def get_katakana_cost(word_length)
        word_length > MAX_KATAKANA_LENGTH ? 8192 : KATAKANA_COSTS[word_length]
      end

      def dictionary
        @dictionary ||= Dictionary.cj
      end

    end
  end
end
