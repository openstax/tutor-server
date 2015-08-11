require 'rails_helper'

RSpec.describe Api::V1::ExerciseRepresenter, type: :representer do
  let!(:exercise) { FactoryGirl.create :content_exercise }
  let!(:lo) {
    FactoryGirl.create :content_tag,
                       tag_type: :lo,
                       value: 'ost-tag-lo-k12phys-ch04-s02-lo01',
                       name: nil,
                       description: 'Describe Newton\'s first law and friction'
  }
  let!(:lo2) {
    FactoryGirl.create :content_tag,
                       tag_type: :lo,
                       value: 'ost-tag-lo-k12phys-ch04-s02-lo02',
                       name: 'Learning Objective 2',
                       description: nil,
                       visible: false
  }
  let!(:teks) {
    FactoryGirl.create :content_tag,
                       value: 'ost-tag-teks-112-39-c-4d',
                       name: '(D)',
                       description: 'calculate the effect of forces on objects'
  }
  let!(:lo_teks) { FactoryGirl.create :content_lo_teks_tag, lo: lo, teks: teks }
  let!(:exercise_tag) { FactoryGirl.create :content_exercise_tag, exercise: exercise, tag: lo }
  let!(:exercise_tag_2) { FactoryGirl.create :content_exercise_tag, exercise: exercise, tag: lo2 }
  let!(:exercise_tag_3) { FactoryGirl.create :content_exercise_tag, exercise: exercise, tag: teks }
  let!(:ecosystem_exercise) {
    strategy = ::Content::Strategies::Direct::Exercise.new(exercise)
    ::Content::Exercise.new(strategy: strategy)
  }

  it 'represents an exercise with tags' do
    representation = Api::V1::ExerciseRepresenter.new(ecosystem_exercise).as_json
    expect(representation).to eq(
      'id' => exercise.id.to_s,
      'url' => exercise.url,
      'content' => JSON.parse(exercise.content),
      'tags' => [{
        'id' => 'ost-tag-lo-k12phys-ch04-s02-lo01',
        'type' => 'lo',
        'description' => 'Describe Newton\'s first law and friction',
        'chapter_section' => [4,2],
      }, {
        'id' => 'ost-tag-teks-112-39-c-4d',
        'type' => 'teks',
        'name' => '(D)',
        'description' => 'calculate the effect of forces on objects',
        'data' => '4d'
      }]
    )
  end
end
