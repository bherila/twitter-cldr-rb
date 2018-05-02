# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      class Alternation < Component
        attr_reader :elements
        alias :alternates :elements

        def initialize(elements)
          @elements = elements
        end

        def to_regexp_str
          ''.tap do |str|
            str << elements.map { |alt| alt.map(&:to_regexp_str).join }.join('|')
            str << quantifier.to_s
          end
        end
      end

    end
  end
end
