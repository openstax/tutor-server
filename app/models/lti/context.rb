class Lti::Context < ApplicationRecord
  belongs_to :course, subsystem: :course_profile, inverse_of: :lti_contexts
  belongs_to :platform, inverse_of: :contexts

  validates :context_id, presence: true, uniqueness: { scope: :lti_platform_id }
end
