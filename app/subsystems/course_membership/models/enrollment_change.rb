class CourseMembership::Models::EnrollmentChange < Tutor::SubSystems::BaseModel
  belongs_to :enrollment
  belongs_to :period

  enum status: [ :pending, :succeeded, :failed ]

  validates :enrollment, presence: true, uniqueness: true
  validates :period, presence: true
end
