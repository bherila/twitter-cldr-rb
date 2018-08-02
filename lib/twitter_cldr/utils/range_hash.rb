module TwitterCldr
  module Utils
    class RangeHash
      def self.from_hash(hash)
        int_pairs = []

        start = nil
        last_key = nil
        last_value = nil
        idx = 0

        int_keys, non_int_keys = hash.keys.partition do |key|
          key.is_a?(Integer)
        end

        int_keys.sort.each do |key|
          unless last_key
            last_key = key
            start = key
            last_value = hash[key]
            next
          end

          if key != last_key + 1 || hash[key] != last_value
            int_pairs << [idx, start..last_key, last_value]
            start = key
            idx += 1
          end

          last_key = key
          last_value = hash[key]
        end

        if !int_pairs.last || int_pairs.last.last != last_value
          int_pairs << [idx, start..last_key, last_value]
        end

        non_int_pairs = non_int_keys.each_with_object({}) do |k, ret|
          ret[k] = hash[k]
        end

        new(int_pairs, non_int_pairs)
      end

      def initialize(int_pairs, non_int_pairs = {})
        @int_pairs = int_pairs
        @non_int_pairs = non_int_pairs
        @index_cache = {}
        @entry_cache = {}
        @include_cache = {}
      end

      def [](key)
        @entry_cache[key] ||= begin
          if key.is_a?(Integer)
            if idx = find(key)
              @int_pairs[idx].last
            end
          else
            @non_int_pairs[key]
          end
        end
      end

      def include?(key)
        return @non_int_pairs.include?(key) unless key.is_a?(Integer)
        range = find(key)
        return !!range
      end

      private

      def find(key)
        @index_cache[key] ||= begin
          idx, _, _ = @int_pairs.bsearch do |pair|
            if pair[1].cover?(key)
              0
            elsif key < pair[1].first
              -1
            else
              1
            end
          end

          idx
        end
      end
    end
  end
end
