module Tasks::Models
  class ConceptCoachTask < Tutor::SubSystems::BaseModel

    CORE_EXERCISES_COUNT = 4
    SPACED_EXERCISES_MAP = [[2, 1], [4, 1], [nil, 1]]

    belongs_to :task, subsystem: :entity
    belongs_to :page, subsystem: :content

    validates :task, presence: true, uniqueness: true
    validates :page, presence: true

  end
end
