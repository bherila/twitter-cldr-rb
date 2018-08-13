# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils
    class RangeHash
      def self.from_hash(hash)
        last_key = nil
        last_value = nil
        start_key = nil
        start_value = nil
        step = nil
        int_elements = []

        int_keys, other_keys = hash.keys.partition { |k| k.is_a?(Integer) }
        other_elements = other_keys.each_with_object({}) do |k, ret|
          ret[k] = hash[k]
        end

        return new([], other_elements) if int_keys.empty?

        int_keys.sort.each do |key|
          value = hash[key]

          unless last_key
            last_key = key
            last_value = value
            start_key = key
            start_value = value
            next
          end

          step ||= (value - last_value).abs

          if key - last_key != 1 || step > 1 || (value - last_value).abs != step
            int_elements << [start_key..last_key, start_value..last_value]
            start_key = key
            start_value = value
            step = nil
          end

          last_key = key
          last_value = value
        end

        lingering = [start_key..last_key, start_value..last_value]
        int_elements << lingering unless int_elements.last == lingering

        int_elements = int_elements.map do |elem|
          if elem.last.size == 1
            [elem.first, elem.last.first]
          else
            elem
          end
        end

        new(int_elements, other_elements)
      end

      attr_reader :int_elements, :other_elements

      def initialize(int_elements, other_elements)
        @int_elements = int_elements
        @other_elements = other_elements
      end

      def init_with(coder)
        int_elems = coder[:int_elements].map do |int_elem|
          first, last = int_elem[0].split('..')
          key = (first.to_i)..(last.to_i)

          value = if int_elem[1].is_a?(String)
            first, last = int_elem[1].split('..')
            (first.to_i)..(last.to_i)
          else
            int_elem[1].to_i
          end

          [key, value]
        end

        initialize(int_elems, coder[:other_elements])
      end

      def encode_with(coder)
        coder[:int_elements] = @int_elements.map do |int_element|
          [
            "#{int_element[0].first}..#{int_element[0].last}",
            int_element[1].is_a?(Range) ? "#{int_element[1].first}..#{int_element[1].last}" : int_element[1]
          ]
        end

        coder[:other_elements] = @other_elements
      end

      def [](key)
        cache[key] ||= begin
          return other_elements[key] unless key.is_a?(Integer)
          key_range, val_or_range = find(key)
          return nil unless key_range
          return val_or_range if val_or_range.is_a?(Integer)
          val_or_range.first + (key - key_range.first)
        end
      end

      def include?(key)
        return other_elements.include?(key) unless key.is_a?(Integer)
        !!find(key)
      end

      def to_h
        int_elements.flat_map { |elem| elem.first.to_a } + other_elements.keys
      end

      private

      def cache
        @cache ||= {}
      end

      def find(key)
        int_elements.bsearch do |pair|
          if pair[0].cover?(key)
            0
          elsif key < pair[0].first
            -1
          else
            1
          end
        end
      end
    end
  end
end
