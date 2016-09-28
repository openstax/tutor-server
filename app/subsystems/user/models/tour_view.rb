module User
  module Models
    class TourView < Tutor::SubSystems::BaseModel

      belongs_to :tour

      belongs_to :profile, -> { with_deleted }, inverse_of: :tour_views

    end
  end
end
