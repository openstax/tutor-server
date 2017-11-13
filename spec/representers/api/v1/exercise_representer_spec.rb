require 'rails_helper'

RSpec.describe Api::V1::ExerciseRepresenter, type: :representer do

  let(:exercise_model) { FactoryBot.create :content_exercise }
  let(:exercise)       {
    strategy = ::Content::Strategies::Direct::Exercise.new(exercise_model)
    ::Content::Exercise.new(strategy: strategy)
  }
  let(:representation)  { Api::V1::ExerciseRepresenter.new(exercise).as_json }

  context 'with tags' do
    before do
      lo = FactoryBot.create :content_tag,
                              tag_type: :lo,
                              value: 'ost-tag-lo-k12phys-ch04-s02-lo01',
                              name: nil,
                              description: 'Describe Newton\'s first law and friction'

      lo2 = FactoryBot.create :content_tag,
                               tag_type: :lo,
                               value: 'ost-tag-lo-k12phys-ch04-s02-lo02',
                               name: 'Learning Objective 2',
                               description: nil,
                               visible: false

      teks = FactoryBot.create :content_tag,
                                value: 'ost-tag-teks-112-39-c-4d',
                                name: '(D)',
                                description: 'calculate the effect of forces on objects'

      FactoryBot.create :content_lo_teks_tag, lo: lo, teks: teks
      FactoryBot.create :content_exercise_tag, exercise: exercise_model, tag: lo
      FactoryBot.create :content_exercise_tag, exercise: exercise_model, tag: lo2
      FactoryBot.create :content_exercise_tag, exercise: exercise_model, tag: teks
    end

    it 'represents an exercise' do
      expect(representation).to include(
        'id' => exercise.id.to_s,
        'url' => exercise.url,
        'content' => JSON.parse(exercise.content),
        'tags' => a_collection_containing_exactly(
          {
            'id' => 'ost-tag-lo-k12phys-ch04-s02-lo01',
            'type' => 'lo',
            'description' => 'Describe Newton\'s first law and friction',
            'chapter_section' => [4,2],
            'is_visible' => true
          },
          {
            "id"=>"ost-tag-lo-k12phys-ch04-s02-lo02",
            "type"=>"lo",
            "name"=>"Learning Objective 2",
            "chapter_section"=>[4, 2],
            "is_visible"=>false
          },
          {
            'id' => 'ost-tag-teks-112-39-c-4d',
            'type' => 'teks',
            'name' => '(D)',
            'description' => 'calculate the effect of forces on objects',
            'is_visible' => true,
            'data' => '4d'
          }
        ),
        'has_interactive' => false,
        'has_video' => false,
        'page_uuid' => exercise.page.uuid
      )
    end
  end

  context 'with interactive and preview' do
    before do
      exercise_model.update_attribute :preview, '<div class="preview interactive">Interactive</div>'
      exercise_model.update_attribute :content, {
        stimulus_html: '<iframe src="https://connexions.github.io/simulations/cool-sim/"></iframe>'
      }.to_json
      exercise_model.update_attribute :has_interactive, true
    end

    it 'represents an exercise' do
      expect(representation).to include(
        'id' => exercise.id.to_s,
        'url' => exercise.url,
        'preview' => exercise.preview,
        'content' => JSON.parse(exercise.content),
        'tags' => [],
        'has_interactive' => true,
        'has_video' => false,
        'page_uuid' => exercise.page.uuid
      )
    end
  end

  context 'with video and preview' do
    before do
      exercise_model.update_attribute :preview, '<div class="preview video">Video</div>'
      exercise_model.update_attribute :content, {
        stimulus_html: '<iframe src="https://www.youtube.com/embed/C00l_Vid/"></iframe>'
      }.to_json
      exercise_model.update_attribute :has_video, true
    end

    it 'represents an exercise' do
      expect(representation).to include(
        'id' => exercise.id.to_s,
        'url' => exercise.url,
        'preview' => exercise.preview,
        'content' => JSON.parse(exercise.content),
        'tags' => [],
        'has_interactive' => false,
        'has_video' => true,
        'page_uuid' => exercise.page.uuid
      )
    end
  end

  context 'with context' do
    before do
      exercise_model.update_attribute :context, '<p>Very important context</p>'
    end

    it 'represents an exercise' do
      expect(representation).to include(
        'id' => exercise.id.to_s,
        'url' => exercise.url,
        'context' => exercise.context,
        'content' => JSON.parse(exercise.content),
        'tags' => [],
        'has_interactive' => false,
        'has_video' => false,
        'page_uuid' => exercise.page.uuid
      )
    end
  end

end
