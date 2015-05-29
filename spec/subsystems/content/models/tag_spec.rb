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

  it 'picks a default DOK name' do
    expect(Content::Models::Tag.new(value: 'dok1').name).to eq('DOK 1')
  end

  it 'picks a default Blooms name' do
    expect(Content::Models::Tag.new(value: 'blooms-3').name).to eq('Blooms 3')
  end
end
