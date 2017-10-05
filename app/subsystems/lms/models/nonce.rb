class Lms::Models::Nonce < Tutor::SubSystems::BaseModel
  belongs_to :app, subsystem: :lms

  validates :app, presence: true
  validates :value, presence: true, uniqueness: { scope: :lms_app_id }
end
