class Tasking < ActiveRecord::Base
  belongs_to :assignee, polymorphic: true
  belongs_to :task, counter_cache: true
  belongs_to :user

  validates :assignee, presence: true
  validates :task, presence: true,
                   uniqueness: { scope: [:assignee_type, :assignee_id] }
  validates :user, presence: true, uniqueness: { scope: :task_id }

  validate :user_matches_assignee

  def user_matches_assignee
    return true if assignee == user || assignee.user == user
    errors.add(:user, 'does not agree with assignee')
    false
  end
end
