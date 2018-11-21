require 'pry-byebug'

class RangeHash
  def self.from_hash(hash)
    return new([]) if hash.empty?

    last_key = nil
    last_value = nil
    start_key = nil
    start_value = nil
    int_elements = []

    int_keys, other_keys = hash.keys.partition { |k| k.is_a?(Integer) }
    other_elements = other_keys.each_with_object({}) do |k, ret|
      ret[k] = hash[k]
    end

    int_keys.sort.each do |key|
      value = hash[key]

      unless last_key
        last_key = key
        last_value = value
        start_key = key
        start_value = value
        next
      end

      if key - last_key != 1 || value - last_value > 1
        int_elements << [start_key..last_key, start_value..last_value]
        start_key = key
        start_value = value
      end

      last_key = key
      last_value = value
    end

    lingering = [start_key..last_key, start_value..last_value]
    int_elements << lingering unless int_elements.last == lingering

    new(int_elements, other_elements)
  end

  attr_reader :int_elements, :other_elements

  def initialize(int_elements, other_elements)
    @int_elements = int_elements
    @other_elements = other_elements
  end

  def [](key)
    cache[key] ||= begin
      return other_elements[key] unless key.is_a?(Integer)
      key_range, val_range = find(key)
      return nil unless key_range
      val_range.first + (key - key_range.first)
    end
  end

  def include?(key)
    return other_elements.include?(key) unless key.is_a?(Integer)
    !!find(key)
  end

  private

  def cache
    @cache ||= {}
  end

  def find(key)
    elements.bsearch do |pair|
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

rh = RangeHash.from_hash(
  1 => 2, 2 => 2, 3 => 4, 4 => 4
)

binding.pry
exit 0
