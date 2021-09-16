class Lti::Platform < ApplicationRecord
  belongs_to :profile, subsystem: :user, optional: true, inverse_of: :lti_platforms

  has_many :users, inverse_of: :platform
  has_many :contexts, inverse_of: :platform
end
