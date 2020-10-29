require 'rails_helper'

RSpec.describe Tasks::ClosePracticeTask, type: :routine do
  let(:student)    { FactoryBot.create :course_membership_student }
  let(:role)       { student.role }
  let(:tasked) do
    FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: role, task_type: :practice_saved)
  end
  let(:task) { tasked.task_step.task }

  it 'closes a practice task' do
    outs = described_class.call(id: task.id, role: role).outputs
    task = Tasks::GetPracticeTask[role: role, task_type: :practice_saved]
    expect(task).to eq(nil)
  end
end
