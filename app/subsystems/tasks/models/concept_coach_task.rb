module Tasks::Models
  class ConceptCoachTask < IndestructibleRecord

    CORE_EXERCISES_COUNT = 3
    SPACED_EXERCISES_MAP = [[2, 1], [:random, 1]]

    belongs_to :page, subsystem: :content
    belongs_to :role, subsystem: :entity
    belongs_to :task, inverse_of: :concept_coach_task

    validates :role, uniqueness: { scope: :content_page_id }
    validates :task, uniqueness: true
    validate :same_role

    protected

    def same_role
      return if task.nil? || task.taskings.map(&:role).include?(role)

      errors.add(:role, 'must match the role the task is assigned to')
      throw :abort
    end
  end
end
