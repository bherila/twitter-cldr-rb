# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      class Quantifier
        class << self
          def from(text)
            case text
              when '*' then any
              when '+' then at_least_one
              when '?' then at_most_one
              else
                min, max = text.gsub(/[{}]/, '').split(',')
                min = min.to_i
                max = max ? max.to_i : Float::INFINITY
                new(min, max, text)
            end
          end

          def blank
            @blank = new(1, 1, '')
          end

          private

          def any
            @any ||= new(0, Float::INFINITY, '*')
          end

          def at_least_one
            @at_least_one ||= new(1, Float::INFINITY, '+')
          end

          def at_most_one
            @at_most_one ||= new(0, 1, '?')
          end
        end

        attr_reader :min, :max

        def initialize(min, max, str)
          @min = min
          @max = max
          @str = str
        end

        def to_s
          @str
        end

        def blank?
          max == 1 && min == 1
        end

        def in_bounds?(value)
          value >= min && value <= max
        end
      end

    end
  end
end
