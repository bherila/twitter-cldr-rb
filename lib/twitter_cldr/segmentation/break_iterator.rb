# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class NonNormalizedStringError < StandardError; end

    class BreakIterator

      DICTIONARY_BREAK_ENGINES = [
        CjBreakEngine,
        BurmeseBreakEngine,
        KhmerBreakEngine,
        LaoBreakEngine,
        ThaiBreakEngine
      ]

      class << self
        # all dictionary characters, i.e. characters that must be handled
        # by one of the dictionary-based break engines
        def dictionary_set
          @dictionary_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
            DICTIONARY_BREAK_ENGINES.each do |break_engine|
              set.add_set(break_engine.word_set)
            end
          end
        end

        def break_engine_for(codepoint)
          codepoint_to_engine_cache[codepoint] ||= begin
            engine = DICTIONARY_BREAK_ENGINES.find do |break_engine|
              break_engine.word_set.include?(codepoint)
            end

            engine || UnhandledBreakEngine.instance
          end
        end

        private

        def codepoint_to_engine_cache
          @codepoint_to_engine_cache ||= {}
        end
      end

      attr_reader :locale, :options

      def initialize(locale = TwitterCldr.locale, options = {})
        @locale = locale
        @options = options
      end

      def each_sentence(str, &block)
        rule_set = rule_set_for('sentence')
        each_boundary(rule_set, get_cursor_for(str), &block)
      end

      def each_word(str)
        unless TwitterCldr::Normalization.normalized?(str, using: :nfkc)
          raise NonNormalizedStringError, 'string must be normalized using the NFKC '\
            'normalization form in order for the segmentation engine to function correctly'
        end

        return to_enum(__method__, str) unless block_given?

        each_word_boundary(str).each_cons(2) do |start, stop|
          yield str[start...stop], start, stop
        end
      end

      def each_grapheme_cluster(str, &block)
        raise NotImplementedError,
          "Grapheme segmentation is not currently supported."
      end

      def each_line(str, &block)
        raise NotImplementedError,
          "Line segmentation is not currently supported."
      end

      private

      def is_dictionary_cp?(codepoint)
        self.class.dictionary_set.include?(codepoint)
      end

      def get_cursor_for(str)
        Cursor.new(str)
      end

      def each_boundary(rule_set, cursor)
        if block_given?
          rule_set.each_boundary(cursor).each_cons(2) do |start, stop|
            yield str[start...stop], start, stop
          end
        else
          to_enum(__method__, rule_set, str)
        end
      end

      def each_word_boundary(str, &block)
        return to_enum(__method__, str) unless block_given?

        rule_set = rule_set_for('word')
        cursor = get_cursor_for(str)

        # implicit start of text boundary
        last_boundary = 0
        yield 0

        until cursor.eos?
          stop = cursor.position

          # loop until we find a dictionary character
          until stop >= cursor.length || is_dictionary_cp?(cursor.codepoints[stop])
            stop += 1
          end

          # break with normal, regex-based rule set
          if stop > cursor.position
            rule_set.each_boundary(cursor, stop) do |boundary|
              last_boundary = boundary
              yield boundary
            end
          end

          # make sure we're not at the end of the road after breaking the
          # latest sequence of non-dictionary characters
          break if cursor.eos?

          # find appropriate dictionary-based break engine
          break_engine = self.class.break_engine_for(cursor.current_cp)

          # break using dictionary-based engine
          break_engine.instance.each_boundary(cursor) do |boundary|
            last_boundary = boundary
            yield boundary
          end
        end

        # implicit end of text boundary
        yield cursor.length if last_boundary != cursor.length
      end

      def rule_set_for(boundary_type)
        RuleSet.load(locale, boundary_type, options)
      end
    end
  end
end
