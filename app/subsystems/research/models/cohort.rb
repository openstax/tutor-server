class Research::Models::Cohort < ApplicationRecord
  belongs_to :study, inverse_of: :cohorts
  has_many :cohort_members, inverse_of: :cohort, dependent: :destroy
  has_many :study_brains, inverse_of: :cohort, dependent: :destroy

  before_create :verify_study_inactive
  before_destroy :verify_no_members

  validates :name, presence: true

  scope :accepting_members, -> { where(is_accepting_members: true) }

  protected

  def verify_study_inactive
    errors.add(:base, "Cannot create a cohort for an active study") if study.active?
    errors.none?
  end

  def verify_no_members
    errors.add(:base, "Cannot destroy a cohort with members") if cohort_members_count > 0
    errors.none?
  end

end
