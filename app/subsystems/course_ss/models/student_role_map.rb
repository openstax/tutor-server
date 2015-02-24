class CourseSs::StudentRoleMap < ActiveRecord::Base
  ## using class_name as bug workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :entity_ss_role,   class_name: "::EntitySs::Role"
  belongs_to :entity_ss_course, class_name: "::EntitySs::Course"

  validates_presence_of :entity_ss_role_id
  validates_presence_of :entity_ss_course_id
end
