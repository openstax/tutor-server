class Lms::Models::Nonce < ApplicationRecord
  validates :value, presence: true, uniqueness: { scope: :lms_app_id }

  enum app_type: [:course, :willo]

  def app
    @app ||= case app_type
             when 'willo' then ::Lms::WilloLabs.new
             when 'course' then ::Lms::Models::App.find_by_id(lms_app_id)
             end
  end
end
