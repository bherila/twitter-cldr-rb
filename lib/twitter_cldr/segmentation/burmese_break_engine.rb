# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class BurmeseBreakEngine < PaliBreakEngine

      # how many words in a row are "good enough"?
      BURMESE_LOOKAHEAD = 3

      # will not combine a non-word with a preceding dictionary word longer than this
      BURMESE_ROOT_COMBINE_THRESHOLD = 3

      # will not combine a non-word that shares at least this much prefix with a
      # dictionary word with a preceding word
      BURMESE_PREFIX_COMBINE_THRESHOLD = 3

      # minimum word size
      BURMESE_MIN_WORD = 2

      def fset
        burmese_word_set
      end

      def lookahead
        BURMESE_LOOKAHEAD
      end

      def root_combine_threshold
        BURMESE_ROOT_COMBINE_THRESHOLD
      end

      def prefix_combine_threshold
        BURMESE_PREFIX_COMBINE_THRESHOLD
      end

      def min_word
        BURMESE_MIN_WORD
      end

      private

      def find_suffix(*)
        # not applicable to Burmese
        0
      end

      def burmese_word_set
        @burmese_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Mymr:]&[:Line_Break=SA:]]')
        end
      end

      def mark_set
        @mark_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Mymr:]&[:Line_Break=SA:]&[:M:]]')
          set.add(0x0020)
        end
      end

      def end_word_set
        @end_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_set(burmese_word_set)
        end
      end

      def begin_word_set
        @begin_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          # basic consonants and independent vowels
          set.add(0x1000)
          set.add(0x102A)
        end
      end

      def dictionary
        @dictionary ||= Dictionary.burmese
      end

    end
  end
end
