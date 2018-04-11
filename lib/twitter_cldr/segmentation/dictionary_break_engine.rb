# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class DictionaryBreakEngine

      def each_boundary(text, &block)
        return to_enum(__method__, text) unless block_given?

        text = TwitterCldr::Normalization.normalize(text, using: :nfkc)
        cursor = Cursor.new(text.codepoints, start_position: 0)

        last_boundary = 0
        yield 0

        until cursor.eos?
          stop = cursor.position

          while !cursor.eos? && fset.include?(cursor.text[stop])
            stop += 1
          end

          divide_up_dictionary_range(cursor, stop).each do |boundary|
            last_boundary = boundary
            yield boundary
          end

          skip_char_count = 0

          until cursor.eos? || fset.include?(cursor.current)
            cursor.advance
            skip_char_count += 1
          end

          if skip_char_count > 0
            last_boundary = cursor.position
            yield cursor.position
          end
        end

        if last_boundary < cursor.length
          yield cursor.length
        end
      end

      private

      def divide_up_dictionary_range(*args)
        raise NotImplementedError, "#{__method__} must be defined in derived classes"
      end

      def fset(*args)
        raise NotImplementedError, "#{__method__} must be defined in derived classes"
      end

    end
  end
end
