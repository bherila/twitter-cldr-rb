# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class Cursor
      attr_reader :text, :match_cache
      attr_accessor :position

      def initialize(text, start_position: 0)
        @text = text
        reset(start_position: start_position)
      end

      def current
        text[position]
      end

      def advance(amount = 1)
        @position += amount
      end

      def reset(start_position: 0)
        @position = start_position
        @match_cache = {}
      end

      def eof?
        position >= text.size
      end

      def eos?
        position >= text.size - 1
      end

      def length
        text.length
      end
    end
  end
end
