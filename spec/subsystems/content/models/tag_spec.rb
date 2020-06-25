require 'rails_helper'

RSpec.describe Content::Models::Tag, type: :model do
  let(:tag) { FactoryBot.create :content_tag, value: 'k12phys-ch04-s01-lo01', name: 'jimmy' }

  it { is_expected.to have_many(:page_tags).dependent(:destroy) }
  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:value) }

  it 'returns the book location information' do
    expect(tag.book_location).to eq([4, 1])
  end

  it 'does not pick a default name when name field present' do
    expect(tag.name).to eq 'jimmy'
  end

  it 'does not assign a tag type if tag type is not generic' do
    tag = FactoryBot.create :content_tag, tag_type: :lo
    expect(tag.tag_type).to eq 'lo'
  end

  it 'does not assign the visible field if it is already set' do
    tag = FactoryBot.create :content_tag, visible: true
    expect(tag.visible).to be true

    tag = FactoryBot.create :content_tag, visible: false
    expect(tag.visible).to be false
  end

  it 'creates a generic tag' do
    tag = FactoryBot.create :content_tag
    expect(tag.data).to be_nil
    expect(tag.visible).to be false
  end

  it 'creates a LO tag' do
    expect(tag.tag_type).to eq 'lo'
    expect(tag.data).to be_nil
    expect(tag.visible).to be true
  end

  it 'creates a TEKS tag' do
    tag = FactoryBot.create :content_tag, name: '(4E)', value: 'ost-tag-teks-112-39-c-4e'
    expect(tag.name).to eq '(4E)'
    expect(tag.tag_type).to eq 'teks'
    expect(tag.data).to eq '4e'
    expect(tag.visible).to be true
  end

  it 'creates a DOK tag' do
    tag = FactoryBot.create :content_tag, name: nil, value: 'dok1'
    expect(tag.name).to eq('DOK: 1')
    expect(tag.tag_type).to eq 'dok'
    expect(tag.data).to eq '1'
    expect(tag.visible).to be true
  end

  it 'creates a Blooms tag' do
    tag = FactoryBot.create :content_tag, name: nil, value: 'blooms-3'
    expect(tag.name).to eq('Blooms: 3')
    expect(tag.tag_type).to eq 'blooms'
    expect(tag.data).to eq '3'
    expect(tag.visible).to be true
  end

  it 'creates a Length tag' do
    tag = FactoryBot.create :content_tag, name: nil, value: 'time-short'
    expect(tag.name).to eq('Length: S')
    expect(tag.tag_type).to eq 'time'
    expect(tag.data).to eq 'short'
    expect(tag.visible).to be true

    tag = FactoryBot.create :content_tag, name: nil, value: 'time-medium'
    expect(tag.name).to eq('Length: M')
    expect(tag.tag_type).to eq 'time'
    expect(tag.data).to eq 'medium'
    expect(tag.visible).to be true

    tag = FactoryBot.create :content_tag, name: nil, value: 'time-long'
    expect(tag.name).to eq('Length: L')
    expect(tag.tag_type).to eq 'time'
    expect(tag.data).to eq 'long'
    expect(tag.visible).to be true
  end
end
