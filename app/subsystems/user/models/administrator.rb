module User
  module Models
    class Administrator < Tutor::SubSystems::BaseModel
      belongs_to :profile, inverse_of: :administrator

      validates :profile, presence: true, uniqueness: true
    end
  end
end
