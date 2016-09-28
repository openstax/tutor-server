module User
  module Models
    class Tour < Tutor::SubSystems::BaseModel

      validates :identifier, presence: true, uniqueness: true, format: /\A[a-z\-]+\z/
    end
  end
end
