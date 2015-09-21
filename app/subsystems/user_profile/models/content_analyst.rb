class UserProfile::Models::ContentAnalyst < Tutor::SubSystems::BaseModel
  belongs_to :profile, inverse_of: :content_analyst

  validates :profile, presence: true, uniqueness: true
end
