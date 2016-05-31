require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::Exercise, type: :external do
  let(:title)    { 'Some Title' }
  let(:hash)     { OpenStax::Exercises::V1.fake_client.new_exercise_hash
                                          .merge(title: title, tags: ['i-am-lo01', 'generic-tag']) }
  let(:exercise) { described_class.new(content: content) }

  context 'without interactives or videos' do
    let(:content) { hash.to_json }

    it 'returns attributes from the exercise JSON' do
      expect(exercise.preview).to be_nil
      expect(exercise.content).to eq content
      expect(exercise.url).to eq "#{OpenStax::Exercises::V1.server_url}/exercises/#{hash[:uid]}"
      expect(exercise.title).to eq title
      expect(exercise.question_answers[0].length).to eq 2
      expect(exercise.correct_question_answer_ids[0][0]).to eq exercise.question_answers[0][0]['id']
      expect(exercise.feedback_map[exercise.question_answers[0][0]['id']]).to eq 'Right!'
      expect(exercise.feedback_map[exercise.question_answers[0][1]['id']]).to eq 'Wrong!'
      expect(exercise.tags).to eq ['i-am-lo01', 'generic-tag']
      expect(exercise.los).to eq ['i-am-lo01']
      expect(exercise.is_multipart?).to eq false
      expect(exercise.has_interactive?).to eq false
      expect(exercise.has_video?).to eq false
    end
  end

  context 'with an interactive' do
    let(:content) { hash.merge(
      stimulus_html: '<iframe src="https://connexions.github.io/simulations/cool-sim/"></iframe>'
    ).to_json }

    it 'can generate a preview for the interactive' do
      expect(exercise.preview).to include('<div class="preview interactive">Interactive</div>')
      expect(exercise.content).to eq content
      expect(exercise.has_interactive?).to eq true
      expect(exercise.has_video?).to eq false
    end
  end

  context 'with a video' do
    let(:content) { hash.merge(
      stimulus_html: '<iframe src="https://www.youtube.com/embed/C00l_Vid/"></iframe>'
    ).to_json }

    it 'can generate a preview for the interactive' do
      expect(exercise.preview).to include('<div class="preview video">Video</div>')
      expect(exercise.content).to eq content
      expect(exercise.has_interactive?).to eq false
      expect(exercise.has_video?).to eq true
    end
  end
end
