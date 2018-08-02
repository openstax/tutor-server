require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::Exercise, type: :external do
  let(:nickname)  { 'Some Nickname' }
  let(:title)     { 'Some Title' }
  let(:context)   { 'Some Context' }
  let(:hash)      do
    OpenStax::Exercises::V1::FakeClient.new_exercise_hash.merge(nickname: nickname, title: title)
  end
  let(:exercise)  do
    described_class.new(content: content).tap{ |exercise| exercise.context = context }
  end

  context 'without interactives or videos' do
    let(:tags)    { ['i-am-lo01', 'generic-tag', 'requires-context:y'] }
    let(:content) { hash.merge(tags: tags).to_json }

    it 'returns attributes from the exercise JSON' do
      expect(exercise.preview).to be_nil
      expect(exercise.context).to eq context
      expect(exercise.content).to eq content
      expect(exercise.url).to eq "#{OpenStax::Exercises::V1.server_url}/exercises/#{hash[:uid]}"
      expect(exercise.nickname).to eq nickname
      expect(exercise.title).to eq title
      expect(exercise.question_answers[0].length).to eq 2
      expect(exercise.correct_question_answer_ids[0][0]).to eq exercise.question_answers[0][0]['id']
      expect(exercise.feedback_map[exercise.question_answers[0][0]['id']]).to eq 'Right!'
      expect(exercise.feedback_map[exercise.question_answers[0][1]['id']]).to eq 'Wrong!'
      expect(exercise.tags).to eq tags
      expect(exercise.los).to eq ['i-am-lo01']
      expect(exercise.is_multipart?).to eq false
      expect(exercise.has_interactive?).to eq false
      expect(exercise.has_video?).to eq false
      expect(exercise.requires_context?).to eq true
    end
  end

  context 'with an interactive' do
    let(:content) { hash.merge(
      stimulus_html: '<iframe src="https://connexions.github.io/simulations/cool-sim/"></iframe>'
    ).to_json }

    it 'can generate a preview for the interactive' do
      expect(exercise.preview).to include context
      expect(exercise.preview).to include '<div class="preview interactive">Interactive</div>'
      expect(exercise.context).to eq context
      expect(exercise.context).to eq context
      expect(exercise.content).to eq content
      expect(exercise.has_interactive?).to eq true
      expect(exercise.has_video?).to eq false
      expect(exercise.requires_context?).to eq false
    end
  end

  context 'with a video' do
    let(:content) { hash.merge(
      stimulus_html: '<iframe src="https://www.youtube.com/embed/C00l_Vid/"></iframe>'
    ).to_json }

    it 'can generate a preview for the interactive' do
      expect(exercise.preview).to include context
      expect(exercise.preview).to include '<div class="preview video">Video</div>'
      expect(exercise.context).to eq context
      expect(exercise.content).to eq content
      expect(exercise.has_interactive?).to eq false
      expect(exercise.has_video?).to eq true
      expect(exercise.requires_context?).to eq false
    end
  end
end
