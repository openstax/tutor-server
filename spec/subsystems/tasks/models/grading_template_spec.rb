require 'rails_helper'

RSpec.describe Tasks::Models::GradingTemplate, type: :model do
  subject { FactoryBot.create :tasks_grading_template }

  it { is_expected.to belong_to(:course) }

  [
    :task_plan_type, :name, :completion_weight, :correctness_weight, :auto_grading_feedback_on,
    :manual_grading_feedback_on, :late_work_immediate_penalty, :late_work_per_day_penalty,
    :default_open_time, :default_due_time, :default_due_date_offset_days,
    :default_close_date_offset_days
  ].each { |field| it { is_expected.to validate_presence_of(field) } }

  [ :completion_weight, :correctness_weight ].each do |field|
    it do
      is_expected.to(
        validate_numericality_of(field).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1)
      )
    end
  end

  it 'validates format of default times' do
    subject.default_open_time = '16:32'
    expect(subject).to be_valid

    subject.default_due_time = '16:'
    expect(subject).not_to be_valid

    subject.default_open_time = '24:00'
    expect(subject).not_to be_valid

    subject.default_due_time = '23:60'
    expect(subject).not_to be_valid
  end
end
