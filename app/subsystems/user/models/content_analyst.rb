module User
  module Models
    class ContentAnalyst < Tutor::SubSystems::BaseModel
      belongs_to :profile, -> { with_deleted }, inverse_of: :content_analyst

      validates :profile, presence: true, uniqueness: true
    end
  end
end
