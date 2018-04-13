# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class BreakIterator

      class << self
        # all dictionary characters, i.e. characters that must be handled
        # by one of the dictionary-based break engines (fyi this takes a
        # few seconds to compute)
        def dictionary_set
          @dictionary_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
            set.add_set(CjBreakEngine.instance.fset)
            set.add_set(BurmeseBreakEngine.instance.fset)
            set.add_set(KhmerBreakEngine.instance.fset)
            set.add_set(LaoBreakEngine.instance.fset)
            set.add_set(ThaiBreakEngine.instance.fset)
          end
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

      def each_word(str, &block)
        rule_set = rule_set_for('word')
        each_boundary(rule_set, get_cursor_for(str), &block)
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

      def get_cursor_for(str)
        Cursor.new(
          TwitterCldr::Normalization.normalize(str, using: :nfkc)
        )
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

      def rule_set_for(boundary_type)
        RuleSet.load(locale, boundary_type, options)
      end
    end
  end
end
