class Tasks::Models::GradingTemplate < ApplicationRecord
  belongs_to :course, subsystem: :course_profile, inverse_of: :grading_templates

  has_many :task_plans, inverse_of: :grading_template

  enum task_plan_type: [ :reading, :homework ]
  enum auto_grading_feedback_on:   [ :answer, :due, :publish ], _prefix: true
  enum manual_grading_feedback_on: [ :grade, :publish ], _prefix: true

  validates :task_plan_type, :name, :auto_grading_feedback_on, :manual_grading_feedback_on,
            :late_work_immediate_penalty, :late_work_per_day_penalty, :default_open_time,
            :default_due_time, :default_due_date_offset_days, :default_close_date_offset_days,
            presence: true

  validates :completion_weight, :correctness_weight,
            presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  validate :default_times_have_good_values

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
end