module User
  module Models
    class TourView < ApplicationRecord

      belongs_to :tour, inverse_of: :tour_views

      belongs_to :profile, inverse_of: :tour_views

      validates :tour,       presence: true, uniqueness: { scope: :user_profile_id }
      validates :view_count, presence: true
      validates :profile,    presence: true

    end
  end
end
