require 'rails_helper'

RSpec.describe Content::Routines::CreateTags, type: :routine do
  let!(:tag_defs) {
    {
      'ost-tag-teks-112-39-c-4d' => {
        name: '(D)',
        description: 'calculate the effect of forces on objects, including the law of inertia, the relationship between force and acceleration, and the nature of force pairs between objects',
      },
      'ost-tag-teks-112-39-c-4f' => {},
      'ost-tag-lo-k12phys-ch04-s02-lo02' => {
        name: 'Discuss the relationship between mass and inertia',
        teks: 'ost-tag-teks-112-39-c-4d'
      }
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
    expect(result_tags.length).to eq 3

    result_tags.sort! { |a, b| a.value <=> b.value }

    expect(result_tags[0].name).to eq 'Discuss the relationship between mass and inertia'
    expect(result_tags[0].description).to be_nil
    expect(result_tags[0].teks_tags).to eq([result_tags[1]])

    expect(result_tags[1].name).to eq '(D)'
    expect(result_tags[1].description).to eq 'calculate the effect of forces on objects, including the law of inertia, the relationship between force and acceleration, and the nature of force pairs between objects'
    expect(result_tags[1].teks_tags).to be_empty

    expect(result_tags[2].name).to be_nil
    expect(result_tags[2].description).to be_nil
    expect(result_tags[2].teks_tags).to be_empty
  end
end
