# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'spec_helper'

include TwitterCldr::Utils

describe RangeHash do
  let(:range_hash) { described_class.from_hash(hash) }

  context 'with an empty hash' do
    let(:hash) { {} }

    describe '.from_hash' do
      it 'builds an empty range hash' do
        expect(range_hash.int_elements).to eq([])
        expect(range_hash.other_elements).to eq({})
      end
    end

    describe '#[]' do
      it 'returns nil for all keys' do
        expect(range_hash[0]).to eq(nil)
        expect(range_hash[1]).to eq(nil)
        expect(range_hash[100]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'returns false for all keys' do
        expect(range_hash).to_not include(0)
        expect(range_hash).to_not include(1)
        expect(range_hash).to_not include(100)
      end
    end
  end

  context 'with sequential int keys and the same value' do
    let(:hash) { { 1 => 1, 2 => 1, 3 => 1, 4 => 1 } }

    describe '.from_hash' do
      it 'correctly rangifies the hash' do
        expect(range_hash.int_elements).to eq([[1..4, 1]])
      end
    end

    describe '#[]' do
      it 'maps keys to values correctly' do
        expect(range_hash[1]).to eq(1)
        expect(range_hash[2]).to eq(1)
        expect(range_hash[3]).to eq(1)
        expect(range_hash[4]).to eq(1)
      end

      it 'returns nil for non-existent keys' do
        expect(range_hash[0]).to eq(nil)
        expect(range_hash[5]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'ensures all present items are included' do
        expect(range_hash).to include(1)
        expect(range_hash).to include(2)
        expect(range_hash).to include(3)
        expect(range_hash).to include(4)
      end

      it 'returns nil for all non-existent items' do
        expect(range_hash).to_not include(0)
        expect(range_hash).to_not include(5)
      end
    end
  end

  context 'with sequential int keys and values' do
    let(:hash) { { 1 => 2, 2 => 3, 3 => 4 } }

    describe '.from_hash' do
      it 'correctly rangifies the hash' do
        expect(range_hash.int_elements).to eq([[1..3, 2..4]])
      end
    end

    describe '#[]' do
      it 'maps keys to values correctly' do
        expect(range_hash[1]).to eq(2)
        expect(range_hash[2]).to eq(3)
        expect(range_hash[3]).to eq(4)
      end

      it 'returns nil for non-existent keys' do
        expect(range_hash[0]).to eq(nil)
        expect(range_hash[5]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'ensures all present items are included' do
        expect(range_hash).to include(1)
        expect(range_hash).to include(2)
        expect(range_hash).to include(3)
      end

      it 'returns nil for all non-existent items' do
        expect(range_hash).to_not include(0)
        expect(range_hash).to_not include(5)
      end
    end
  end

  context 'with non-sequential int keys' do
    let(:hash) { { 1 => 2, 3 => 3, 5 => 4 } }

    describe '.from_hash' do
      it 'correctly rangifies the hash' do
        expect(range_hash.int_elements).to eq([[1..1, 2], [3..3, 3], [5..5, 4]])
      end
    end

    describe '#[]' do
      it 'maps keys to values correctly' do
        expect(range_hash[1]).to eq(2)
        expect(range_hash[3]).to eq(3)
        expect(range_hash[5]).to eq(4)
      end

      it 'returns nil for non-existent keys' do
        expect(range_hash[0]).to eq(nil)
        expect(range_hash[4]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'ensures all present items are included' do
        expect(range_hash).to include(1)
        expect(range_hash).to include(3)
        expect(range_hash).to include(5)
      end

      it 'returns nil for all non-existent items' do
        expect(range_hash).to_not include(0)
        expect(range_hash).to_not include(4)
      end
    end
  end

  context 'with sequential then equal values' do
    let(:hash) { { 1 => 2, 2 => 3, 3 => 3, 4 => 5, 5 => 6 } }

    describe '.from_hash' do
      it 'correctly rangifies the hash' do
        expect(range_hash.int_elements).to eq(
          [[1..2, 2..3], [3..3, 3], [4..5, 5..6]]
        )
      end
    end

    describe '#[]' do
      it 'maps keys to values correctly' do
        expect(range_hash[1]).to eq(2)
        expect(range_hash[2]).to eq(3)
        expect(range_hash[3]).to eq(3)
        expect(range_hash[4]).to eq(5)
        expect(range_hash[5]).to eq(6)
      end

      it 'returns nil for non-existent keys' do
        expect(range_hash[0]).to eq(nil)
        expect(range_hash[6]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'ensures all present items are included' do
        expect(range_hash).to include(1)
        expect(range_hash).to include(2)
        expect(range_hash).to include(3)
        expect(range_hash).to include(4)
        expect(range_hash).to include(5)
      end

      it 'returns nil for all non-existent items' do
        expect(range_hash).to_not include(0)
        expect(range_hash).to_not include(6)
      end
    end
  end

  context 'with some non-integer keys' do
    let(:hash) { { 1 => 2, 2 => 3, else: 4 } }

    describe '.from_hash' do
      it 'correctly rangifies the hash' do
        expect(range_hash.int_elements).to eq([[1..2, 2..3]])
        expect(range_hash.other_elements).to eq({ else: 4 })
      end
    end

    describe '#[]' do
      it 'ensures all present items are included' do
        expect(range_hash[:else]).to eq(4)
      end

      it 'returns nil for non-existent keys' do
        expect(range_hash[:foo]).to eq(nil)
      end
    end

    describe '#include?' do
      it 'ensures all present items are included' do
        expect(range_hash).to include(:else)
      end

      it 'returns nil for all non-existent items' do
        expect(range_hash).to_not include(:foo)
      end
    end
  end
end
