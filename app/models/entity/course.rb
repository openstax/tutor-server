class Entity::Course < Tutor::SubSystems::BaseModel
  has_one :profile, subsystem: :course_profile, dependent: :destroy, autosave: true

  has_many :periods, subsystem: :course_membership, dependent: :destroy
  has_many :teachers, subsystem: :course_membership, dependent: :destroy
  has_many :students, subsystem: :course_membership, dependent: :destroy

  has_many :excluded_exercises, subsystem: :course_content, dependent: :destroy

  has_many :course_ecosystems, subsystem: :course_content, dependent: :destroy
  has_many :ecosystems, through: :course_ecosystems, subsystem: :content

  has_many :course_assistants, subsystem: :tasks, dependent: :destroy

  has_many :taskings, through: :periods, subsystem: :tasks

  delegate :name, :appearance_code, :is_concept_coach, :offering, :teacher_join_token,
           :time_zone, :default_open_time, :default_due_time,
           :name=, :default_open_time=, :default_due_time=, to: :profile

  def deletable?
    periods.empty? && teachers.empty? && students.empty?
  end
end
