class AssignedTask < ActiveRecord::Base
  belongs_to :assignee, polymorphic: true
  belongs_to :task, counter_cache: true
  belongs_to :user

  validate :user_matches_assignee

  def user_matches_assignee
    return true if assignee == user || assignee.user == user
    errors.add(:user, 'does not agree with assignee')
    false
  end
end
