module User
  module Models
    class TourView < ApplicationRecord

      belongs_to :tour, inverse_of: :tour_views

      belongs_to :profile, inverse_of: :tour_views

      validates :tour,       uniqueness: { scope: :user_profile_id }
      validates :view_count, presence: true

    end
  end
end
