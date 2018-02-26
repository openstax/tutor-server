class Research::Models::Cohort < IndestructibleRecord
  belongs_to :study, inverse_of: :cohorts

  validates :name, presence: true
end
