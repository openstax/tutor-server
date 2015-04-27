require 'rails_helper'

RSpec.describe Content::Models::Tag, :type => :model do
  let!(:tag) { FactoryGirl.create :content_tag, value: 'k12phys-ch04-s01-lo01' }
  it { is_expected.to have_many(:page_tags).dependent(:destroy) }
  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to validate_presence_of(:tag_type) }

  it 'returns the chapter and section information' do
    expect(tag.chapter_section).to eq('4.1')
  end
end
