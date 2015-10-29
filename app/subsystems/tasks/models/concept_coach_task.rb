module Tasks::Models
  class ConceptCoachTask < Tutor::SubSystems::BaseModel
    belongs_to :task, subsystem: :entity
    belongs_to :page, subsystem: :content

    validates :task, presence: true, uniqueness: true
    validates :page, presence: true
  end
end
