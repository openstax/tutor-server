class Research::Models::Cohort < IndestructibleRecord
  belongs_to :study, inverse_of: :cohorts
  has_many :cohort_members

  before_create :verify_study_inactive

  validates :name, presence: true

  protected

  def verify_study_inactive
    errors.add(:base, "Cannot create a cohort for an active study") if study.active?
    errors.none?
  end
end
