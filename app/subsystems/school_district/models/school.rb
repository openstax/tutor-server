module SchoolDistrict
  module Models
    class School < Tutor::SubSystems::BaseModel
      has_many :profiles, subsystem: :course_profile
      belongs_to :district

      validates :name, presence: true,
                       uniqueness: { scope: :school_district_district_id }

      delegate :name,
        to: :district,
        prefix: true,
        allow_nil: true
    end
  end
end
