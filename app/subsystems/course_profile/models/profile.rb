class CourseProfile::Profile < ActiveRecord::Base
  belongs_to :course, subsystem: :entity

  validates :name, presence: true
end