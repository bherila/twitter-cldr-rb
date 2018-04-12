# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class ThaiBreakEngine < PaliBreakEngine

      # how many words in a row are "good enough"?
      THAI_LOOKAHEAD = 3

      # will not combine a non-word with a preceding dictionary word longer than this
      THAI_ROOT_COMBINE_THRESHOLD = 3

      # will not combine a non-word that shares at least this much prefix with a
      # dictionary word with a preceding word
      THAI_PREFIX_COMBINE_THRESHOLD = 3

      # ellision character
      THAI_PAIYANNOI = 0x0E2F

      # repeat character
      THAI_MAIYAMOK = 0x0E46

      # minimum word size
      THAI_MIN_WORD = 2

      # minimum number of characters for two words
      THAI_MIN_WORD_SPAN = THAI_MIN_WORD * 2

      def lookahead
        THAI_LOOKAHEAD
      end

      def root_combine_threshold
        THAI_ROOT_COMBINE_THRESHOLD
      end

      def prefix_combine_threshold
        THAI_PREFIX_COMBINE_THRESHOLD
      end

      def min_word
        THAI_MIN_WORD_SPAN
      end

      def fset
        thai_word_set
      end

      private

      def advance_past_suffix(cursor, end_pos, state)
        suffix_length = 0

        if cursor.position < end_pos && state.word_length > 0
          uc = cursor.current

          if state.words[state.words_found].candidates(cursor, dictionary, end_pos) <= 0 && suffix_set.include?(uc)
            if uc == THAI_PAIYANNOI
              unless suffix_set.include?(cursor.previous)
                # skip over previous end and PAIYANNOI
                cursor.advance(2)
                suffix_length += 1
                uc = cursor.current
              else
                # restore prior position
                cursor.advance
              end
            end

            if uc == THAI_MAIYAMOK
              if cursor.previous != THAI_MAIYAMOK
                # skip over previous end and MAIYAMOK
                cursor.advance(2)
                suffix_length += 1
              else
                # restore prior position
                cursor.advance
              end
            end
          else
            cursor.position = state.current + state.word_length
          end
        end

        suffix_length
      end

      def thai_word_set
        @thai_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Thai:]&[:Line_Break=SA:]]')
        end
      end

      def mark_set
        @mark_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Thai:]&[:Line_Break=SA:]&[:M:]]')
          set.add(0x0020)
        end
      end

      def end_word_set
        @end_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_set(thai_word_set)
          set.subtract(0x0E31)  # MAI HAN-AKAT
          set.subtract_range(0x0E40..0x0E44)  # SARA E through SARA AI MAIMALAI
        end
      end

      def begin_word_set
        @begin_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_range(0x0E01..0x0E2E)  # KO KAI through HO NOKHUK
          set.add_range(0x0E40..0x0E44)  # SARA E through SARA AI MAIMALAI
        end
      end

      def suffix_set
        @suffix_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add(THAI_PAIYANNOI)
          set.add(THAI_MAIYAMOK)
        end
      end

      def dictionary
        @dictionary ||= Dictionary.thai
      end

    end
  end
end
