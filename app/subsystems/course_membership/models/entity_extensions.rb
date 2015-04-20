Entity::Role.has_many :students, subsystem: :course_membership
Entity::Role.has_many :teachers, subsystem: :course_membership
