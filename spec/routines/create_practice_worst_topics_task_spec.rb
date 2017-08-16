require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe CreatePracticeWorstTopicsTask, type: :routine do

  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: course, role: role }

  it 'errors when there are not enough local exercises for the widget' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_practice_worst_areas_exercises).and_return(
      {
        accepted: true,
        exercises: [],
        spy_info: {}
      }
    )
    expect { result }
      .to  not_change { Tasks::Models::Task.count }
      .and not_change { Tasks::Models::Tasking.count }
      .and not_change { Tasks::Models::TaskStep.count }
      .and not_change { Tasks::Models::TaskedExercise.count }
      .and not_change { course.reload.sequence_number }
    expect(result.errors.first.code).to eq :no_exercises
  end

end
