Entity::Role.has_many :students, subsystem: :course_membership, foreign_key: 'entity_role_id'
Entity::Role.has_many :teachers, subsystem: :course_membership, foreign_key: 'entity_role_id'
