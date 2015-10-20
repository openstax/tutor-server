class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel
  belongs_to :profile, subsystem: :user
  belongs_to :period

  enum status: [ :pending, :succeeded, :failed ]

  validates :profile, presence: true
  validates :period, presence: true

  def latest?
    created_at >= profile.enrollment_changes.maximum(:created_at)
  end
end
