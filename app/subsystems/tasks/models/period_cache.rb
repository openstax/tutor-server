class Tasks::Models::PeriodCache < ApplicationRecord
  json_serialize :as_toc, Hash

  belongs_to :period,    subsystem: :course_membership
  belongs_to :ecosystem, subsystem: :content
  belongs_to :task_plan

  validates :period, :ecosystem, presence: true
  validates :task_plan, uniqueness: {
    scope: [ :course_membership_period_id, :content_ecosystem_id ]
  }

  validates :opens_at, :due_at, :feedback_at, timeliness: { type: :date }, allow_nil: true

  def practice?
    tasks_task_plan_id.nil?
  end

  def as_toc
    @toc ||= super.deep_symbolize_keys
  end

  def reload
    @toc = nil
    super
  end
end
