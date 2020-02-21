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
    expect { expect(result.errors.first.code).to eq :no_exercises }
      .to  change { Tasks::Models::Task.count }.by(1)
      .and change { Tasks::Models::Tasking.count }.by(1)
      .and not_change { Tasks::Models::TaskStep.count }
      .and not_change { Tasks::Models::TaskedPlaceholder.count }
      .and change { course.reload.sequence_number }.by(2)
  end

  it 'non-fatal errors when Biglearn does not return an accepted response after max attempts' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return(
      {
        accepted: false,
        exercises: [],
        spy_info: {}
      }
    )
    expect { expect(result.errors).to be_empty }
      .to  change { Tasks::Models::Task.count }.by(1)
      .and change { Tasks::Models::Tasking.count }.by(1)
      .and change { Tasks::Models::TaskStep.count }.by(1)
      .and change { Tasks::Models::TaskedPlaceholder.count }.by(1)
      .and change { course.reload.sequence_number }.by(1)
  end
end
