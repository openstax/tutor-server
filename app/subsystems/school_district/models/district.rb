module SchoolDistrict
  module Models
    class District < Tutor::SubSystems::BaseModel
      has_many :schools, subsystem: :school_district

      validates :name, presence: true, uniqueness: true
    end
  end
end
