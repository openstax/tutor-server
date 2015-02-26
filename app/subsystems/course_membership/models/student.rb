class CourseMembership::Student < ActiveRecord::Base
  ## using class_name as workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :entity_role,   class_name: "::Entity::Role"
  belongs_to :entity_course, class_name: "::Entity::Course"

  validates_presence_of :entity_role_id
  validates_presence_of :entity_course_id
end
