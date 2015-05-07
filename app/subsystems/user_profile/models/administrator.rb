class UserProfile::Models::Administrator < Tutor::SubSystems::BaseModel

  belongs_to :profile, inverse_of: :administrator, class_name: 'UserProfile::Models::Profile'

  validates :profile, presence: true, uniqueness: true
end
