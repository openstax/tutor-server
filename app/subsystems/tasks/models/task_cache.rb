class Tasks::Models::TaskCache < ApplicationRecord
  json_serialize :as_toc, Hash

  belongs_to :task
  belongs_to :ecosystem, subsystem: :content

  enum task_type: Tasks::Models::Task.task_types.keys

  validates :task_type, presence: true
  validates :ecosystem, uniqueness: { scope: :tasks_task_id }

  validates :opens_at, :due_at, :feedback_at, timeliness: { type: :date }, allow_nil: true
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
