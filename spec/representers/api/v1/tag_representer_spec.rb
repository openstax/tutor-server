require 'rails_helper'

RSpec.describe Api::V1::TagRepresenter, type: :representer do

  let!(:lo_tag) {
    FactoryGirl.create :content_tag,
                       value: 'k12phys-ch04-s02-lo02',
                       tag_type: :lo,
                       name: 'Discuss the relationship between mass and inertia',
                       description: nil
  }

  let!(:teks_tag) {
    FactoryGirl.create :content_tag,
                       value: 'ost-tag-teks-112-39-c-4d',
                       tag_type: :teks,
                       name: '(D)',
                       description: 'calculate the effect of forces on objects'
  }

  let!(:generic_tag) { FactoryGirl.create :content_tag }

  it 'represents a LO tag' do
    representation = Api::V1::TagRepresenter.new(lo_tag).as_json
    expect(representation).to eq(
      'id' => 'k12phys-ch04-s02-lo02',
      'name' => 'Discuss the relationship between mass and inertia',
      'type' => 'lo',
      'chapter_section' => '4.2'
    )
  end

  it 'represents a TEKS tag' do
    representation = Api::V1::TagRepresenter.new(teks_tag).as_json
    expect(representation).to eq(
      'id' => 'ost-tag-teks-112-39-c-4d',
      'name' => '(D)',
      'description' => 'calculate the effect of forces on objects',
      'type' => 'teks',
    )
  end

  it 'represents a generic tag' do
    representation = Api::V1::TagRepresenter.new(generic_tag).as_json
    expect(representation).to eq(
      'id' => generic_tag.value,
      'name' => generic_tag.name,
      'description' => generic_tag.description,
      'type' => 'generic',
    )
  end

end
