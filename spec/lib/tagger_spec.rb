require 'rails_helper'

RSpec.describe Tagger, type: :lib do
  let(:tag_hashes)    do
    [
      { value: 'stax-phys-ch01-s02-lo03', name: nil, type: :lo },
      { value: 'stax-bio-ch04-s05-aplo-06', name: nil, type: :aplo },
      { value: 'dok7', name: 'DOK: 7', type: :dok },
      { value: 'blooms-8', name: 'Blooms: 8', type: :blooms },
      { value: 'time-short', name: 'Length: S', type: :length },
      { value: 'ost-tag-teks-dont-care-9a', name: nil, type: :teks },
      { value: 'k12phys-ch10-s11', name: nil, type: :generic }
    ]
  end

  let(:correct_data) do
    [ nil, nil, '7', '8', 'short', '9a', nil ]
  end

  let(:correct_book_locations) do
    [ [1, 2], [4, 5], [], [], [], [], [10, 11] ]
  end

  it 'generates correct tag types' do
    tag_hashes.each do |hash|
      expect(described_class.get_type(hash[:value])).to eq hash[:type]
    end
  end

  it 'generates correct tag data' do
    tag_hashes.each_with_index do |hash, index|
      type = described_class.get_type(hash[:value])
      expect(described_class.get_data(type, hash[:value])).to eq correct_data[index]
    end
  end

  it 'generates correct tag names' do
    tag_hashes.each do |hash|
      type = described_class.get_type(hash[:value])
      data = described_class.get_data(type, hash[:value])
      expect(described_class.get_name(type, data)).to eq hash[:name]
    end
  end

  it 'generates correct tag book_locations' do
    tag_hashes.each_with_index do |hash, index|
      expect(described_class.get_book_location(hash[:value])).to eq correct_book_locations[index]
    end
  end
end
