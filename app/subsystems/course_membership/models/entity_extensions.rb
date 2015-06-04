require_dependency '../models/entity/course'
require_dependency '../models/entity/role'

Entity::Course.has_many :periods, subsystem: :course_membership
Entity::Course.has_many :teachers, subsystem: :course_membership

Entity::Role.has_many :students, subsystem: :course_membership
Entity::Role.has_many :teachers, subsystem: :course_membership
