# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class DictionaryBreakEngine

      def each_boundary(text, &block)
        text = TwitterCldr::Normalization.normalize(text, using: :nfkc)
        codepoints = text.codepoints

        stop = codepoints.find_index { |cp| !fset.include?(cp) }
        stop ||= codepoints.size - 1

        divide_up_dictionary_range(codepoints, 0, stop).each(&block)
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
