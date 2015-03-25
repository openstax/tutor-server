class Entity::Role < ActiveRecord::Base
  has_many :students, subsystem: :course_membership
  has_many :teachers, subsystem: :course_membership
end
