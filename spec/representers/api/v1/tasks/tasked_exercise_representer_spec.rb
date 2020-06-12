require 'rails_helper'
require_relative 'tasked_exercise_representer_shared_examples'

RSpec.describe Api::V1::Tasks::TaskedExerciseRepresenter, type: :representer do
  include_examples 'a tasked_exercise representer'

  context 'non-completed exercise' do
    it "'published_points' is not included" do
      expect(representation).not_to include('published_points')
    end

    it "'published_comments' is not included" do
      expect(representation).not_to include('published_comments')
    end
  end

  context 'completed exercise' do
    before do
      allow(task_step).to receive(:completed?).and_return(true)

      allow(tasked_exercise).to receive(:free_response).and_return('Some response')
      allow(tasked_exercise).to receive(:answer_id).and_return('123')
      allow(tasked_exercise).to receive(:cache_key).and_return('tasks/models/tasked_exercises/43')
      allow(tasked_exercise).to receive(:cache_version).and_return('test')
    end

    context 'feedback available' do
      before { allow(tasked_exercise).to receive(:feedback_available?).and_return(true) }

      it "'published_points' is included" do
        expect(representation).to include('published_points' => 0.5)
      end

      it "'published_comments' is included" do
        expect(representation).to include('published_comments' => 'Hi')
      end
    end

    context 'feedback unavailable' do
      it "'published_points' is not included" do
        expect(representation).to_not include('published_points')
      end

      it "'published_comments' is not included" do
        expect(representation).to_not include('published_comments')
      end
    end
  end
end
