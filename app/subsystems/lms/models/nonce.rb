class Lms::Models::Nonce < ApplicationRecord
#  belongs_to :app, subsystem: :lms

  #  validates :app, presence: true

  validates :value, presence: true, uniqueness: { scope: :lms_app_id }

  enum app_type: [:course, :willow]

  def app
    @app ||= case app_type
             when 'willow' then ::Lms::WillowLabs.new
             when 'course' then ::Lms::Models::App.find_by_id(lms_app_id)
             end
  end
end
