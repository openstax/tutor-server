require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do
  let(:tasked_exercise) { FactoryBot.create :tasks_tasked_exercise }
  let(:task)            { tasked_exercise.task_step.task }
  let(:ecosystem)       { task.ecosystem }
  let(:represented)     { described_class.new(task).to_hash }

  it 'includes fields' do
    expect(represented).to include(
      'title' => task.title,
      'type' => task.task_type,
      'due_at' => DateTimeUtilities.to_api_s(task.due_at),
      'students' => [],
    )
  end

  it 'includes ecosystem information in the spy' do
    expect(represented['spy']).to(
      eq("ecosystem_id" => ecosystem.id, "ecosystem_title" => ecosystem.title)
    )
  end

  it 'includes auto_grading_feedback_on feedback availability' do
    task.task_plan.grading_template.auto_grading_feedback_on = :answer
    expect(described_class.new(task).to_hash['auto_grading_feedback_on']).to eq 'answer'

    task.task_plan.grading_template.auto_grading_feedback_on = :due
    expect(described_class.new(task).to_hash['auto_grading_feedback_on']).to eq 'due'

    task.task_plan.grading_template.auto_grading_feedback_on = :publish
    expect(described_class.new(task).to_hash['auto_grading_feedback_on']).to eq 'publish'
  end

  it 'includes manual_grading_feedback_on feedback availability' do
    task.task_plan.grading_template.manual_grading_feedback_on = :grade
    expect(described_class.new(task).to_hash['manual_grading_feedback_on']).to eq 'grade'

    task.task_plan.grading_template.manual_grading_feedback_on = :publish
    expect(described_class.new(task).to_hash['manual_grading_feedback_on']).to eq 'publish'
  end

  it 'includes is_deleted' do
    task.task_plan.withdrawn_at = nil
    expect(described_class.new(task).to_hash).to include('is_deleted' => false)
    task.task_plan.withdrawn_at = Time.current.yesterday
    expect(described_class.new(task).to_hash).to include('is_deleted' => true)
    task.task_plan.withdrawn_at = Time.current.tomorrow
    expect(described_class.new(task).to_hash).to include('is_deleted' => true)
  end

  it 'includes student roles' do
    task = FactoryBot.create(:tasks_task, ecosystem: ecosystem, num_random_taskings: 1)
    expect(described_class.new(task).to_hash['students']).to have(1).items
    expect(described_class.new(task).to_hash).to include(
      'students' => task.roles.map { |role| { role_id: role.id, name: role.course_member.name } }
    )
  end
end
