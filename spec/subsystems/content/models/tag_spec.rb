require 'rails_helper'

RSpec.describe Content::Models::Tag, :type => :model do
  let!(:tag) { FactoryGirl.create :content_tag, value: 'k12phys-ch04-s01-lo01', name: 'jimmy' }

  it { is_expected.to have_many(:page_tags).dependent(:destroy) }
  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to validate_presence_of(:tag_type) }

  it 'returns the chapter and section information' do
    expect(tag.chapter_section).to eq([4, 1])
  end

  it 'does not pick a default name when name field present' do
    expect(tag.name).to eq 'jimmy'
  end

  it 'does not assign a tag type if tag type is not generic' do
    tag = FactoryGirl.create :content_tag, tag_type: :lo
    expect(tag.tag_type).to eq 'lo'
  end

  it 'creates a LO tag' do
    expect(tag.tag_type).to eq 'lo'
  end

  it 'creates a TEKS tag' do
    tag = FactoryGirl.create :content_tag, name: '(4E)', value: 'ost-tag-teks-112-39-c-4e'
    expect(tag.name).to eq '(4E)'
    expect(tag.tag_type).to eq 'teks'
  end

  it 'creates a DOK tag' do
    tag = FactoryGirl.create :content_tag, name: nil, value: 'dok1'
    expect(tag.name).to eq('DOK: 1')
    expect(tag.tag_type).to eq 'dok'
  end

  it 'creates a Blooms tag' do
    tag = FactoryGirl.create :content_tag, name: nil, value: 'blooms-3'
    expect(tag.name).to eq('Blooms: 3')
    expect(tag.tag_type).to eq 'blooms'
  end

  it 'creates a Length tag' do
    tag = FactoryGirl.create :content_tag, name: nil, value: 'time-short'
    expect(tag.name).to eq('Length: S')
    expect(tag.tag_type).to eq 'length'

    tag = FactoryGirl.create :content_tag, name: nil, value: 'time-med'
    expect(tag.name).to eq('Length: M')

    tag = FactoryGirl.create :content_tag, name: nil, value: 'time-long'
    expect(tag.name).to eq('Length: L')
  end
end
