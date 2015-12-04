class Entity::Course < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile

  has_many :periods, subsystem: :course_membership
  has_many :teachers, subsystem: :course_membership
  has_many :students, subsystem: :course_membership

  has_many :course_ecosystems, subsystem: :course_content
  has_many :ecosystems, through: :course_ecosystems, subsystem: :content

  has_many :course_assistants, subsystem: :tasks

  has_many :taskings, through: :periods, subsystem: :tasks

  delegate :name, :appearance_code, :is_concept_coach, :offering, :teacher_join_token, to: :profile
end
