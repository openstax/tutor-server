class Research::Models::CohortMember < ApplicationRecord
  belongs_to :cohort, inverse_of: :cohort_members, counter_cache: true
  belongs_to :student, subsystem: :course_membership, inverse_of: :cohort_members

  validates :cohort, presence: true
  validates :student, presence: true
end
