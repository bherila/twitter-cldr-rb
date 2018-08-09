# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      # Can exist inside and outside of character classes
      class MulticharString < Component

        attr_reader :codepoints

        def initialize(codepoints)
          @codepoints = codepoints
        end

        def to_set
          TwitterCldr::Utils::RangeSet.new([codepoints..codepoints])
        end

        def to_regexp_str
          array_to_regex(Array(codepoints)) + quantifier.to_s
        end

        def to_s
          to_regexp_str
        end

      end
    end
  end
end
