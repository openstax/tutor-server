require 'rails_helper'

RSpec.describe Api::V1::ExerciseRepresenter, type: :representer do
  let!(:exercise) { FactoryGirl.create :content_exercise }
  let!(:lo) {
    FactoryGirl.create :content_tag,
                       tag_type: :lo,
                       value: 'ost-tag-lo-k12phys-ch04-s02-lo01',
                       name: 'Describe Newton\'s first law and friction',
                       description: nil
  }
  let!(:teks) {
    FactoryGirl.create :content_tag,
                       value: 'ost-tag-teks-112-39-c-4d',
                       name: '(D)',
                       description: 'calculate the effect of forces on objects'
  }
  let!(:lo_teks) { FactoryGirl.create :content_lo_teks_tag, lo: lo, teks: teks }
  let!(:exercise_tag) {
    FactoryGirl.create :content_exercise_tag,
                       exercise: exercise,
                       tag: lo
  }

  it 'represents an exercise with tags' do
    representation = Api::V1::ExerciseRepresenter.new(exercise).as_json
    expect(representation).to eq(
      'id' => exercise.id,
      'url' => exercise.url,
      'content' => JSON.parse(exercise.content),
      'tags' => [{
        'id' => 'ost-tag-lo-k12phys-ch04-s02-lo01',
        'type' => 'lo',
        'name' => 'Describe Newton\'s first law and friction',
        'chapter_section' => '4.2',
      }, {
        'id' => 'ost-tag-teks-112-39-c-4d',
        'type' => 'generic',
        'name' => '(D)',
        'description' => 'calculate the effect of forces on objects'
      }]
    )
  end
end
