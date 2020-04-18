require 'rails_helper'
require_relative 'tasked_exercise_representer_shared_examples'

RSpec.describe Api::V1::Tasks::TaskedExerciseGradingRepresenter, type: :representer do
  include_examples 'a tasked_exercise representer'

  before do
    allow(tasked_exercise).to receive(:grader_points).and_return(0.5)
    allow(tasked_exercise).to receive(:grader_comments).and_return('Hi')
    allow(tasked_exercise).to receive(:last_graded_at).and_return(Time.current)
  end

  context 'grader_points' do
    it 'can be read' do
      expect(representation).to include('grader_points' => 0.5)
    end

    it 'can be written' do
      expect(tasked_exercise).to receive(:grader_points=).with(0.25)
      described_class.new(tasked_exercise).from_hash('grader_points' => 0.25)
    end
  end

  context 'grader_comments' do
    it 'can be read' do
      expect(representation).to include('grader_comments' => 'Hi')
    end

    it 'can be written' do
      expect(tasked_exercise).to receive(:grader_comments=).with('Hello there')
      described_class.new(tasked_exercise).from_hash('grader_comments' => 'Hello there')
    end
  end

  context 'last_graded_at' do
    it 'can be read' do
      expect(representation).to include('last_graded_at' => kind_of(String))
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(tasked_exercise).not_to receive(:last_graded_at=)
      described_class.new(tasked_exercise).from_hash(
        'last_graded_at' => DateTimeUtilities.to_api_s(Time.current)
      )
    end
  end
end
