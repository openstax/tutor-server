class Entity::Role < ActiveRecord::Base
  has_many :students, subsystem: :course_membership, foreign_key: 'entity_role_id'
  has_many :teachers, subsystem: :course_membership, foreign_key: 'entity_role_id'
end
