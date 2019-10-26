class CourseMembership::Models::TeacherStudent < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  auto_uuid

  belongs_to :role, subsystem: :entity, inverse_of: :teacher_student
  belongs_to :course, subsystem: :course_profile, inverse_of: :teacher_students
  belongs_to :period, inverse_of: :teacher_students

  validates :role,   uniqueness: true

  delegate :username, :first_name, :last_name, :full_name, :name, :is_test, :research_identifier,
           to: :role
end
