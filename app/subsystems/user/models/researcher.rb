module User
  module Models
    class Researcher < ApplicationRecord
      belongs_to :profile, inverse_of: :researcher

      validates :profile, presence: true, uniqueness: true
    end
  end
end
