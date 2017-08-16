require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe CreatePracticeSpecificTopicsTask, type: :routine do

  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: course, role: role, page_ids: [ page.id ] }

  it 'non-fatal errors when there are not enough local exercises for the widget' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return(
      {
        accepted: true,
        exercises: [],
        spy_info: {}
      }
    )
    expect { result }
      .to  change { Tasks::Models::Task.count }.by(1)
      .and change { Tasks::Models::Tasking.count }.by(1)
      .and not_change { Tasks::Models::TaskStep.count }
      .and not_change { Tasks::Models::TaskedExercise.count }
      .and change { course.reload.sequence_number }.by(2)
    expect(result.errors.first.code).to eq :no_exercises
  end

  it 'non-fatal errors when Biglearn does not return an accepted response after max attempts' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return(
      {
        accepted: false,
        exercises: [],
        spy_info: {}
      }
    )
    expect { result }
      .to  change { Tasks::Models::Task.count }.by(1)
      .and change { Tasks::Models::Tasking.count }.by(1)
      .and not_change { Tasks::Models::TaskStep.count }
      .and not_change { Tasks::Models::TaskedExercise.count }
      .and change { course.reload.sequence_number }.by(2)
    expect(result.errors.first.code).to eq :no_response
  end

end
