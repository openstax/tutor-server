require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe FindOrCreatePracticeSpecificTopicsTask, type: :routine do
  
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

  it 'returns same task id when posted twice' do
    second_result = described_class.call( course: course, role: role, page_ids: [ page.id ] )
    expect { second_result.outputs.task.id == practice_task.id }
  end

  it 'returns a new task when the previous one has been worked' do
    practice_task.task_steps.map { |step| Preview::AnswerExercise.call task_step: step, is_correct: true }
    third_result = described_class.call( course: course, role: role, page_ids: [ page.id ] )
    expect { third_result.outputs.task.id != practice_task.id }
  end
end
