require 'rails_helper'

RSpec.describe Tagger, type: :lib do
  context 'old tags' do
    let(:tag_hashes)    do
      [
        { value: 'k12phys-ch01-s02-lo03', name: nil, type: :lo },
        { value: 'apbio-ch04-s05-aplo-06', name: nil, type: :aplo },
        { value: 'dok7', name: 'DOK: 7', type: :dok },
        { value: 'blooms-8', name: 'Blooms: 8', type: :blooms },
        { value: 'time-short', name: 'Length: S', type: :time },
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

  context 'new tags' do
    let(:tag_hashes)    do
      [
        { value: 'lo:stax-phys:1-2-3', name: nil, type: :lo },
        { value: 'aplo:stax-bio:4-5-6', name: nil, type: :aplo },
        { value: 'aplo:stax-apbio:EVO-1.C', name: nil, type: :aplo },
        { value: 'dok:7', name: 'DOK: 7', type: :dok },
        { value: 'blooms:8', name: 'Blooms: 8', type: :blooms },
        { value: 'time:short', name: 'Length: S', type: :time },
        { value: 'teks:dont-care-9a', name: nil, type: :teks },
        { value: 'context-cnxmod:6a0568d8-23d7-439b-9a01-16e4e73886b3', name: nil, type: :cnxmod },
        { value: 'id:stax-econ:101', name: nil, type: :id },
        { value: 'requires-context:y', name: nil, type: :requires_context },
        { value: 'requires-context:yes', name: nil, type: :requires_context },
        { value: 'requires-context:t', name: nil, type: :requires_context },
        { value: 'requires-context:true', name: nil, type: :requires_context },
        { value: 'context-cnxfeature:fs-featureid', name: nil, type: :cnxfeature },
        { value: 'dont-care', name: nil, type: :generic }
      ]
    end

    let(:correct_data) do
      [ nil, nil, nil, '7', '8', 'short', '9a', '6a0568d8-23d7-439b-9a01-16e4e73886b3',
        '101', nil, nil, nil, nil, 'fs-featureid', nil ]
    end

    let(:correct_book_locations) do
      [ [1, 2], [4, 5], [], [], [], [], [], [], [], [], [], [], [], [], [] ]
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
end
