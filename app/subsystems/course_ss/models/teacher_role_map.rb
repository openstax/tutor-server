class CourseSs::TeacherRoleMap < ActiveRecord::Base
  belongs_to :entity_ss_role
  belongs_to :entity_ss_course

  validates_presence_of :entity_ss_role_id
  validates_presence_of :entity_ss_course_id
end
