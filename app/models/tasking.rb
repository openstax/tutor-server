class Tasking < ActiveRecord::Base
  belongs_to :taskee, polymorphic: true
  belongs_to :task, counter_cache: true
  belongs_to :user, class_name: 'UserProfile::Profile'

  validates :taskee, presence: true
  validates :task, presence: true,
                   uniqueness: { scope: [:taskee_type, :taskee_id] }
  validates :user, presence: true, uniqueness: { scope: :task_id }

  validate :user_matches_taskee

  def user_matches_taskee
    return true if taskee == user || taskee.user == user
    errors.add(:user, 'does not agree with taskee')
    false
  end

end
