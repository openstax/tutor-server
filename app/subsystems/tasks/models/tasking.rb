class Tasks::Models::Tasking < Tutor::SubSystems::BaseModel
  belongs_to :role, subsystem: :entity
  belongs_to :task, subsystem: :entity

  validates :role, presence: true
  validates :task, presence: true,
                   uniqueness: { scope: :entity_role_id }
end

# From legacy tasking:

  # belongs_to :taskee, polymorphic: true
  # belongs_to :task, counter_cache: true
  # belongs_to :user, class_name: 'UserProfile::Models::Profile'

  # validates :taskee, presence: true
  # validates :task, presence: true,
  #                  uniqueness: { scope: [:taskee_type, :taskee_id] }
  # validates :user, presence: true, uniqueness: { scope: :task_id }

  # validate :user_matches_taskee

  # def user_matches_taskee
  #   return true if taskee == user || taskee.user == user
  #   errors.add(:user, 'does not agree with taskee')
  #   false
  # end
