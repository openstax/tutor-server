class Lti::Platform < ApplicationRecord
  belongs_to :profile, subsystem: :user, optional: true
end
