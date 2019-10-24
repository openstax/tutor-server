class CourseMembership::Models::Teacher < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  belongs_to :role, subsystem: :entity, inverse_of: :teacher
  belongs_to :course, subsystem: :course_profile, inverse_of: :teachers

  validates :role,   uniqueness: true

  delegate :username, :first_name, :last_name, :full_name, :name, :is_test, :research_identifier,
           to: :role
end
