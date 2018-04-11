# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    # break engine for languages derived from Pali, i.e. Lao, Thai, Khmer, and Burmese
    class PaliBreakEngine < DictionaryBreakEngine

      private

      def divide_up_dictionary_range(cursor, end_pos)
        return [] if (end_pos - cursor.position) < min_word

        words_found = 0
        words = PossibleWordList.new(lookahead)
        boundaries = []

        while cursor.position < end_pos
          current = cursor.position
          word_length = 0

          # look for candidate words at the current position
          candidates = words[words_found].candidates(
            cursor, dictionary, end_pos
          )

          # if we found exactly one, use that
          if candidates == 1
            word_length = words[words_found].accept_marked(cursor)
            words_found += 1
          elsif candidates > 1
            mark_best_candidate(cursor, words, words_found, end_pos)
            word_length = words[words_found].accept_marked(cursor)
            words_found += 1
          end

          # We come here after having either found a word or not. We look ahead to the
          # next word. If it's not a dictionary word, we will combine it with the word we
          # just found (if there is one), but only if the preceding word does not exceed
          # the threshold. The cursor should now be positioned at the end of the word we
          # found.
          if cursor.position < end_pos && word_length < root_combine_threshold
            # If it is a dictionary word, do nothing. If it isn't, then if there is
            # no preceding word, or the non-word shares less than the minimum threshold
            # of characters with a dictionary word, then scan to resynchronize.
            preceeding_words = words[words_found].candidates(cursor, dictionary, end_pos)

            if preceeding_words <= 0 && (word_length == 0 || words[words_found].longest_prefix < prefix_combine_threshold)
              chars = advance_to_plausible_word_boundary(cursor, words, current, word_length, end_pos)

              # bump the word count if there wasn't already one
              words_found += 1 if word_length <= 0

              # update the length with the passed-over characters
              word_length += chars
            else
              # backup to where we were for next iteration
              cursor.position = current + word_length
            end
          end

          # never stop before a combining mark.
          while cursor.position < end_pos && mark_set.include?(cursor.current)
            cursor.advance
            word_length += 1
          end

          # Look ahead for possible suffixes if a dictionary word does not follow.
          # We do this in code rather than using a rule so that the heuristic
          # resynch continues to function. For example, one of the suffix characters
          # could be a typo in the middle of a word.
          word_length += find_suffix(cursor, words, word_length, end_pos)

          # Did we find a word on this iteration? If so, push it on the break stack
          if word_length > 0
            boundaries << current + word_length
          end
        end

        boundaries
      end

      private

      def advance_to_plausible_word_boundary(cursor, words, current, word_length, end_pos)
        remaining = end_pos - (current + word_length)
        pc = cursor.current
        chars = 0

        loop do
          cursor.advance
          uc = cursor.current
          chars += 1
          remaining -= 1

          break if remaining <= 0

          if end_word_set.include?(pc) && begin_word_set.include?(uc)
            # Maybe. See if it's in the dictionary.
            candidate = words[words_found + 1].candidates(cursor, dictionary, end_pos)
            cursor.position = current + word_length + chars
            break if candidate > 0
          end

          pc = uc
        end

        chars
      end

      def mark_best_candidate(cursor, words, words_found, end_pos)
        # if there was more than one, see which one can take us forward the most words
        found_best = false

        # if we're already at the end of the range, we're done
        if cursor.position < end_pos
          loop do
            words_matched = 1

            if words[words_found + 1].candidates(cursor, dictionary, end_pos) > 0
              if words_matched < 2
                # followed by another dictionary word; mark first word as a good candidate
                words[words_found].mark_current
                words_matched = 2
              end

              # if we're already at the end of the range, we're done
              break if cursor.position >= end_pos

              # see if any of the possible second words is followed by a third word
              loop do
                # if we find a third word, stop right away
                if words[words_found + 2].candidates(cursor, dictionary, end_pos) > 0
                  words[words_found].mark_current
                  found_best = true
                  break
                end

                break unless words[words_found + 1].back_up(cursor)
              end
            end

            break unless words[words_found].back_up(cursor) && !found_best
          end
        end
      end

    end
  end
end
