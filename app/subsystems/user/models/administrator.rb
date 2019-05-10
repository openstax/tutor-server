module User
  module Models
    class Administrator < ApplicationRecord
      belongs_to :profile, inverse_of: :administrator

      validates :profile, uniqueness: true
    end
  end
end
