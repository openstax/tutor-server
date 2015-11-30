module Tasks::Models
  class ConceptCoachTask < Tutor::SubSystems::BaseModel

    CORE_EXERCISES_COUNT = 4
    SPACED_EXERCISES_MAP = [[2, 1], [4, 1], [nil, 1]]

    belongs_to :page, subsystem: :content
    belongs_to :role, subsystem: :entity
    belongs_to :task, subsystem: :entity

    validates :page, presence: true
    validates :role, presence: true, uniqueness: { scope: :content_page_id }
    validates :task, presence: true, uniqueness: true
    validate :same_role

    protected

    def same_role
      return if task.nil? || task.taskings.map(&:role).include?(role)
      errors.add(:role, 'must match the role the task is assigned to')
      false
    end
  end
end
