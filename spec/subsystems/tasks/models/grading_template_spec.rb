require 'rails_helper'

RSpec.describe Tasks::Models::GradingTemplate, type: :model do
  subject(:grading_template) { FactoryBot.create :tasks_grading_template }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to belong_to(:cloned_from).optional }

  it { is_expected.to have_many(:task_plans) }

  [
    :task_plan_type, :name, :completion_weight, :correctness_weight, :auto_grading_feedback_on,
    :manual_grading_feedback_on, :late_work_penalty_applied, :late_work_penalty,
    :default_open_time, :default_due_time, :default_due_date_offset_days,
    :default_close_date_offset_days
  ].each { |field| it { is_expected.to validate_presence_of(field) } }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:course_profile_course_id) }

  [ :completion_weight, :correctness_weight, :late_work_penalty ].each do |field|
    it do
      is_expected.to(
        validate_numericality_of(field).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1)
      )
    end
  end

  let(:course) { grading_template.course }

  it 'validates that the weights add up to 1' do
    (0..10).map { |index| index/10.0 }.each do |completion_weight|
      grading_template.completion_weight = completion_weight
      grading_template.correctness_weight = (1 - completion_weight).round(1)
      expect(grading_template).to be_valid
    end

    grading_template.completion_weight = 0.42
    grading_template.correctness_weight = 0.42
    expect(grading_template).not_to be_valid

    grading_template.completion_weight = 1.42
    grading_template.correctness_weight = -0.42
    expect(grading_template).not_to be_valid

    grading_template.completion_weight = -0.42
    grading_template.correctness_weight = 1.42
    expect(grading_template).not_to be_valid
  end

  it 'validates the format of default times' do
    grading_template.default_open_time = '16:32'
    expect(grading_template).to be_valid

    grading_template.default_due_time = '16:'
    expect(grading_template).not_to be_valid

    grading_template.default_open_time = '24:00'
    expect(grading_template).not_to be_valid

    grading_template.default_due_time = '23:60'
    expect(grading_template).not_to be_valid
  end

  it 'knows if it has task_plans' do
    task_plan = FactoryBot.create :tasks_task_plan, course: course,
                                                    grading_template: grading_template
    expect(grading_template.has_task_plans?).to eq true

    task_plan.destroy
    expect(grading_template.reload.has_task_plans?).to eq false
  end

  it 'cannot change its type if it has task_plans' do
    task_plan = FactoryBot.create :tasks_task_plan, course: course,
                                                    grading_template: grading_template
    old_task_plan_type = grading_template.task_plan_type
    new_task_plan_type = ([ 'reading', 'homework' ] - [ old_task_plan_type ]).sample
    grading_template.task_plan_type = new_task_plan_type
    expect(grading_template.save).to eq false
    expect(grading_template.reload.task_plan_type).to eq old_task_plan_type

    task_plan.destroy
    grading_template.task_plan_type = new_task_plan_type
    expect(grading_template.save).to eq true
    expect(grading_template.reload.task_plan_type).to eq new_task_plan_type
  end

  it 'cannot be updated if it has open task_plans' do
    task_plan = FactoryBot.create :tasks_task_plan, course: course,
                                                    grading_template: grading_template

    task = FactoryBot.create :tasks_task, task_plan: task_plan,
                                          task_type: :reading,
                                          step_types: [:tasks_tasked_reading],
                                          num_random_taskings: 1,
                                          opens_at: 1.day.ago

    DistributeTasks[task_plan: task_plan]

    new_name = 'New'
    grading_template.name = new_name
    expect(grading_template.save).to eq false

    task_plan.destroy
    grading_template.reload

    grading_template.name = new_name
    expect(grading_template.save).to eq true
    expect(grading_template.reload.name).to eq new_name
  end

  it 'cannot be destroyed if it has task_plans' do
    FactoryBot.create(
      :tasks_grading_template, course: course, task_plan_type: grading_template.task_plan_type
    )
    task_plan = FactoryBot.create :tasks_task_plan, course: course,
                                                    grading_template: grading_template
    expect(grading_template.destroy).to eq false
    expect(grading_template.reload.deleted?).to eq false

    task_plan.destroy!
    expect do
      grading_template.reload.destroy!
    end.not_to change { Tasks::Models::GradingTemplate.count }
    expect(grading_template.reload.deleted?).to eq true
  end

  it 'cannot be destroyed if it is the last grading template for a task_plan_type' do
    expect(grading_template.destroy).to eq false
    expect(grading_template.reload.deleted?).to eq false

    grading_template_2 = FactoryBot.create(
      :tasks_grading_template, course: course, task_plan_type: grading_template.task_plan_type
    )
    expect { grading_template.destroy! }.not_to change { Tasks::Models::GradingTemplate.count }
    expect(grading_template.reload.deleted?).to eq true

    expect(grading_template_2.destroy).to eq false
    expect(grading_template_2.reload.deleted?).to eq false
  end

  context '#allow_auto_graded_multiple_attempts' do
    it 'is allowed during validation if auto grading feedback is immediate' do
      grading_template.auto_grading_feedback_on_answer!
      grading_template.allow_auto_graded_multiple_attempts = true
      expect(grading_template).to be_valid
      expect(grading_template.allow_auto_graded_multiple_attempts).to eq true
    end

    it 'is forced to false during validation if auto grading feedback is not immediate' do
      grading_template.auto_grading_feedback_on_due!
      grading_template.allow_auto_graded_multiple_attempts = true
      expect(grading_template).to be_valid
      expect(grading_template.allow_auto_graded_multiple_attempts).to eq false
    end
  end
end
