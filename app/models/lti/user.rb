class Lti::User < ApplicationRecord
  belongs_to :profile, subsystem: :user, optional: true, inverse_of: :lti_users
  belongs_to :platform, inverse_of: :users

  validates :platform, uniqueness: { scope: :user_profile_id }
  validates :uid, presence: true, uniqueness: { scope: :lti_platform_id }
end
