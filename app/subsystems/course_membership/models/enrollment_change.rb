class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel
  belongs_to :profile, subsystem: :user
  belongs_to :enrollment # from
  belongs_to :period     # to

  enum status: [ :pending, :succeeded, :failed ]

  validates :profile, presence: true
  validates :enrollment, uniqueness: { allow_nil: true }
  validates :period, presence: true

  def from_period
    enrollment.try(:period)
  end

  alias_method :to_period, :period
end
