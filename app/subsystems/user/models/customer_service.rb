module User
  module Models
    class CustomerService < ApplicationRecord
      belongs_to :profile, inverse_of: :customer_support

      validates :profile, uniqueness: true
    end
  end
end
