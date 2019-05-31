module User
  module Models
    class ContentAnalyst < ApplicationRecord
      belongs_to :profile, inverse_of: :content_analyst

      validates :profile, uniqueness: true
    end
  end
end
