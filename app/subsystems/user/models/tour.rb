module User
  module Models
    class Tour < ApplicationRecord
      has_many :tour_views, dependent: :destroy, inverse_of: :tour

      validates :identifier, presence: true, uniqueness: true, format: /\A[0-9a-z\-]+\z/
    end
  end
end
