class CourseMembership::Models::TeacherStudent < ApplicationRecord

  acts_as_paranoid without_default_scope: true

  belongs_to :role, subsystem: :entity, inverse_of: :teacher_student
  belongs_to :course, subsystem: :course_profile, inverse_of: :teacher_students
  belongs_to :period, inverse_of: :teacher_students

  validates :role,   presence: true, uniqueness: true
  validates :course, presence: true
  validates :period, presence: true

  delegate :username, :first_name, :last_name, :full_name, :name, to: :role

end
