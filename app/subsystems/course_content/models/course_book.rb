class CourseContent::CourseBook < ActiveRecord::Base
  belongs_to :course, subsystem: :entity
  belongs_to :book, subsystem: :entity

  validates :course, presence: true
  validates :book, presence: true

  validates :book, uniqueness: {scope: :entity_course_id}
end