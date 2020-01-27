class Tasks::Models::TaskCache < ApplicationRecord
  json_serialize :as_toc, Hash

  belongs_to :task
  belongs_to :task_plan, optional: true
  belongs_to :ecosystem, subsystem: :content

  enum task_type: Tasks::Models::Task.task_types.keys

  enum auto_grading_feedback_on:   [ :answer, :due, :publish ], _prefix: true
  enum manual_grading_feedback_on: [ :grade, :publish ], _prefix: true

  validates :task_type, :auto_grading_feedback_on, :manual_grading_feedback_on, presence: true
  validates :ecosystem, uniqueness: { scope: :tasks_task_id }

  validates :opens_at, :due_at, :closes_at, :withdrawn_at,
            timeliness: { type: :date }, allow_nil: true
  validates :is_cached_for_period, inclusion: { in: [ true, false ] }

  def practice?
    chapter_practice? || page_practice? || mixed_practice? || practice_worst_topics?
  end

  def as_toc
    @toc ||= super.deep_symbolize_keys
  end

  def reload
    @toc = nil
    super
  end
end
