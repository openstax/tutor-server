require 'rails_helper'

RSpec.describe Tasks::Models::GradingTemplate, type: :model do
  subject { FactoryBot.create :tasks_grading_template }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to have_many(:task_plans) }

  [
    :task_plan_type, :name, :completion_weight, :correctness_weight, :auto_grading_feedback_on,
    :manual_grading_feedback_on, :late_work_immediate_penalty, :late_work_per_day_penalty,
    :default_open_time, :default_due_time, :default_due_date_offset_days,
    :default_close_date_offset_days
  ].each { |field| it { is_expected.to validate_presence_of(field) } }

  [
    :completion_weight,
    :correctness_weight,
    :late_work_immediate_penalty,
    :late_work_per_day_penalty
  ].each do |field|
    it do
      is_expected.to(
        validate_numericality_of(field).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1)
      )
    end
  end

  let(:course) { subject.course }

  it 'validates that the weights add up to 1' do
    (0..10).map { |index| index/10.0 }.each do |completion_weight|
      subject.completion_weight = completion_weight
      subject.correctness_weight = (1 - completion_weight).round(1)
      expect(subject).to be_valid
    end

    subject.completion_weight = 0.42
    subject.correctness_weight = 0.42
    expect(subject).not_to be_valid

    subject.completion_weight = 1.42
    subject.correctness_weight = -0.42
    expect(subject).not_to be_valid

    subject.completion_weight = -0.42
    subject.correctness_weight = 1.42
    expect(subject).not_to be_valid
  end

  it 'validates the format of default times' do
    subject.default_open_time = '16:32'
    expect(subject).to be_valid

    subject.default_due_time = '16:'
    expect(subject).not_to be_valid

    subject.default_open_time = '24:00'
    expect(subject).not_to be_valid

    subject.default_due_time = '23:60'
    expect(subject).not_to be_valid
  end

  it 'cannot change its type if it has task_plans' do
    task_plan = FactoryBot.create :tasks_task_plan, owner: course, grading_template: subject
    old_task_plan_type = subject.task_plan_type
    new_task_plan_type = ([ 'reading', 'homework' ] - [ old_task_plan_type ]).sample
    subject.task_plan_type = new_task_plan_type
    expect(subject.save).to eq false
    expect(subject.reload.task_plan_type).to eq old_task_plan_type

    task_plan.destroy
    subject.task_plan_type = new_task_plan_type
    expect(subject.save).to eq true
    expect(subject.reload.task_plan_type).to eq new_task_plan_type
  end

  it 'cannot be destroyed if it has task_plans' do
    task_plan = FactoryBot.create :tasks_task_plan, owner: course, grading_template: subject
    expect(subject.destroy).to eq false
    expect(subject.reload.deleted?).to eq false

    task_plan.destroy!
    expect { subject.reload.destroy! }.not_to change { Tasks::Models::GradingTemplate.count }
    expect(subject.reload.deleted?).to eq true
  end
end
