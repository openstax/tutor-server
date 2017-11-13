class Lms::Models::Nonce < ApplicationRecord
  belongs_to :app, subsystem: :lms

  validates :app, presence: true
  validates :value, presence: true, uniqueness: { scope: :lms_app_id }
end
