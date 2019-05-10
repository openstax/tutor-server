class Research::Models::Cohort < ApplicationRecord
  belongs_to :study, inverse_of: :cohorts

  has_many :study_brains, through: :study
  has_many :cohort_members, inverse_of: :cohort, dependent: :destroy

  before_create :verify_study_inactive
  before_destroy :verify_no_members

  validates :name, presence: true

  scope :accepting_members, -> { where(is_accepting_members: true) }
  scope :active, -> { joins(:study).merge(Research::Models::Study.active) }

  protected

  def verify_study_inactive
    return unless study.active?

    errors.add(:base, "Cannot create a cohort for an active study")
    throw :abort
  end

  def verify_no_members
    return if cohort_members_count == 0

    errors.add(:base, "Cannot destroy a cohort with members")
    throw :abort
  end
end
