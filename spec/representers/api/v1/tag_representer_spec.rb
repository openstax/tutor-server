require 'rails_helper'

RSpec.describe Api::V1::TagRepresenter, type: :representer do

  let!(:lo_tag) {
    FactoryGirl.create(:content_tag,
                       value: 'ost-tag-lo-k12phys-ch04-s01-lo01',
                       name: '(4C)',
                       tag_type: 1,
                       description: 'analyze and describe accelerated motion in two dimensions')
  }

  let!(:generic_tag) {
    FactoryGirl.create(:content_tag)
  }

  it 'represents a LO tag' do
    representation = Api::V1::TagRepresenter.new(lo_tag).as_json
    expect(representation).to eq(
      'id' => 'ost-tag-lo-k12phys-ch04-s01-lo01',
      'name' => '(4C)',
      'description' => 'analyze and describe accelerated motion in two dimensions',
      'type' => 'lo',
      'chapter_section' => '4.1'
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
