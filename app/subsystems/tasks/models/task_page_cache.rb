class Tasks::Models::TaskPageCache < ApplicationRecord
  belongs_to :task
  belongs_to :student,     subsystem: :course_membership
  belongs_to :page,        subsystem: :content
  belongs_to :mapped_page, subsystem: :content, class_name: 'Content::Models::Page'

  validates :task, presence: true,
                   uniqueness: { scope: [ :course_membership_student_id, :content_page_id ] }

  validates :student, :page, presence: true

  validates :num_assigned_exercises, :num_completed_exercises, :num_correct_exercises,
            presence: true, numericality: { only_integer: true }

  validates :opens_at, :due_at, :feedback_at, timeliness: { type: :date }, allow_nil: true
end
