class Tasks::Models::GradingTemplate < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  belongs_to :course, subsystem: :course_profile, inverse_of: :grading_templates

  has_many :task_plans, inverse_of: :grading_template

  enum task_plan_type:             [ :reading, :homework ]
  enum auto_grading_feedback_on:   [ :answer, :due, :publish ], _prefix: true
  enum manual_grading_feedback_on: [ :grade, :publish ], _prefix: true
  enum late_work_penalty_applied:  [ :never, :immediately, :daily ]

  validates :task_plan_type,
            :name,
            :auto_grading_feedback_on,
            :manual_grading_feedback_on,
            :default_open_time,
            :default_due_time,
            :default_due_date_offset_days,
            :default_close_date_offset_days,
            :late_work_penalty_applied,
            presence: true

  validates :completion_weight,
            :correctness_weight,
            :late_work_penalty,
            presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  validate :weights_add_up, :default_times_have_good_values

  before_update  :no_task_plans_when_changing_task_plan_type
  before_destroy :no_task_plans_on_destroy, :not_last_template

  DEFAULT_ATTRIBUTES = [
    {
      task_plan_type: :homework,
      name: 'OpenStax Homework',
      completion_weight: 0,
      correctness_weight: 1,
      auto_grading_feedback_on: :answer,
      manual_grading_feedback_on: :publish,
      late_work_penalty_applied: :daily,
      late_work_penalty: 0.1,
      default_open_time: '00:01',
      default_due_time: '07:00',
      default_due_date_offset_days: 7,
      default_close_date_offset_days: 7
    },
    {
      task_plan_type: :reading,
      name: 'OpenStax Reading',
      completion_weight: 0.9,
      correctness_weight: 0.1,
      auto_grading_feedback_on: :answer,
      manual_grading_feedback_on: :grade,
      late_work_penalty_applied: :daily,
      late_work_penalty: 0.1,
      default_open_time: '00:01',
      default_due_time: '07:00',
      default_due_date_offset_days: 7,
      default_close_date_offset_days: 7
    }
  ]

  def self.default
    DEFAULT_ATTRIBUTES.map { |attributes| new(attributes) }
  end

  protected

  def weights_add_up
    return if completion_weight.nil? || correctness_weight.nil? ||
              [ completion_weight, correctness_weight ].sum == 1

    errors.add :base, 'weights must add up to exactly 1'
    throw :abort
  end

  def default_times_have_good_values
    [ :default_open_time, :default_due_time ].each do |time_field|
      value = self.send(time_field)

      next if value.nil?

      match = value.match(/(\d\d):(\d\d)/)

      if match.nil?
        errors.add(time_field.to_sym, 'is not of format "HH:mm"')
        next
      end

      if match[1].to_i > 23 || match[2].to_i > 59
        errors.add(time_field.to_sym, 'has the right syntax but invalid time value')
      end
    end

    throw(:abort) if errors.any?
  end

  def has_task_plans?
    !task_plans.reject(&:withdrawn?).empty?
  end

  def no_task_plans_when_changing_task_plan_type
    return unless task_plan_type_changed? && has_task_plans?

    errors.add :task_plan_type,
               'cannot be changed because this template is assigned to one or more task_plans'
    throw :abort
  end

  def no_task_plans_on_destroy
    return unless has_task_plans?

    errors.add :base, 'cannot be deleted because it is assigned to one or more task_plans'
    throw :abort
  end

  def not_last_template
    return if course.grading_templates.where(
      task_plan_type: task_plan_type
    ).without_deleted.where.not(id: id).exists?

    errors.add :base, "cannot be deleted because it is the last #{task_plan_type} grading template"
    throw :abort
  end
end
