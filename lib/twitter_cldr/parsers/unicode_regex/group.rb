module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      class Group < Component

        attr_reader :elements
        attr_accessor :capturing

        alias :capturing? :capturing

        def initialize
          @elements = []
          @capturing = false
        end

        def to_set
          TwitterCldr::Utils::RangeSet.new.tap do |set|
            elements.each { |element| set.union!(element.to_set) }
          end
        end

        def to_regexp_str
          ''.tap do |str|
            str << '('
            str << '?:' unless capturing?
            elements.each { |element| str << element.to_regexp_str }
            str << ')'
            str << (quantifier || '')
          end
        end

      end

    end
  end
end
