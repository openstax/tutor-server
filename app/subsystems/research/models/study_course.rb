class Research::Models::StudyCourse < ApplicationRecord
  belongs_to :study, inverse_of: :study_courses
  belongs_to :course, subsystem: :course_profile, inverse_of: :study_courses

  validates :study, presence: true
  validates :course, uniqueness: { scope: :research_study_id },
                     presence: true

  before_destroy :only_destroy_if_study_never_active

  protected

  def only_destroy_if_study_never_active
    errors.add(:base, "Cannot remove a course from a study that has been active") if study.ever_active?
    errors.none?
  end
end
