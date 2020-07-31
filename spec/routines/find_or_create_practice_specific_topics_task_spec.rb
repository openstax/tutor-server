require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe FindOrCreatePracticeSpecificTopicsTask, type: :routine do
  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: @course, role: @role, page_ids: [ @page.id ] }

  it 'non-fatal errors when there are not enough local exercises for the widget' do
    expect_any_instance_of(Tasks::FetchAssignmentPes).to receive(:call).and_return(
      Lev::Routine::Result.new(Lev::Outputs.new(exercises: []), Lev::Errors.new)
    )

    expect do
      expect(result.errors.first.code).to eq :no_exercises
    end.to  not_change { Tasks::Models::Task.count }
       .and not_change { Tasks::Models::Tasking.count }
       .and not_change { Tasks::Models::TaskStep.count }
       .and not_change { Tasks::Models::TaskedPlaceholder.count }
  end

  it 'returns same task id when posted twice' do
    second_result = described_class.call( course: @course, role: @role, page_ids: [ @page.id ] )
    expect { second_result.outputs.task.id == practice_task.id }
  end

  it 'returns a new task when the previous one has been worked' do
    practice_task.task_steps.map do |step|
      Preview::AnswerExercise.call task_step: step, is_correct: true
    end
    third_result = described_class.call(course: @course, role: @role, page_ids: [ @page.id ])
    expect { third_result.outputs.task.id != practice_task.id }
  end
end
