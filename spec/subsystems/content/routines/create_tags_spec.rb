require 'rails_helper'

RSpec.describe Content::Routines::CreateTags, type: :routine do
  let!(:tag_defs) {
    {
      'ost-tag-teks-112-39-c-4d' => {
        name: '(D)',
        description: 'calculate the effect of forces on objects, including the law of inertia, the relationship between force and acceleration, and the nature of force pairs between objects',
      },
      'ost-tag-teks-112-39-c-4f' => {}
    }
  }

  it 'create tags' do
    result = nil
    expect {
      result = Content::Routines::CreateTags.call(tag_defs)
    }.to change {
      Content::Models::Tag.all.count
    }.by(tag_defs.length)

    expect(result.errors).to be_empty

    result_tags = result.outputs[:tags]
    expect(result_tags.length).to eq(tag_defs.length)

    result_tags.each do |tag|
      expect(tag.name).to eq(tag_defs[tag.value][:name])
      expect(tag.description).to eq(tag_defs[tag.value][:description])
    end
  end
end
