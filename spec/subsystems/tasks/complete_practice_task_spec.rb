require 'rails_helper'

RSpec.describe Tasks::CompletePracticeTask, type: :routine do
  let(:student)    { FactoryBot.create :course_membership_student }
  let(:role)       { student.role }
  let(:tasked) do
    FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: role, task_type: :practice_saved)
  end
  let(:task) { tasked.task_step.task }

  it 'deletes incomplete task steps' do
    outs = described_class.call(id: task.id, role: role).outputs
    expect(task.task_steps.count).to eq(0)
  end

  it 'does not delete completed task steps' do
    Preview::AnswerExercise.call task_step: tasked.task_step, is_correct: true

    outs = described_class.call(id: task.id, role: role).outputs
    expect(task.task_steps.count).to eq(1)
  end
end
