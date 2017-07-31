module User
  module Models
    class Tour < ApplicationRecord
      has_many :tour_views, dependent: :destroy, inverse_of: :tour

      validates :identifier, presence: true, uniqueness: true, format: /\A[a-z\-]+\z/
    end
  end
end
